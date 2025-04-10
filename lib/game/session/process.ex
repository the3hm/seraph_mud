defmodule Game.Session.Process do
  @moduledoc """
  GenServer process module, client access is at `Game.Session`

  Holds knowledge if the player is logged in, who they are, what they're save is.
  """

  use GenServer, restart: :temporary

  require Logger

  alias Game.Account
  alias Game.Character
  alias Game.Command.Move
  alias Game.Command.Pager
  alias Game.Environment
  alias Game.Format
  alias Game.Format.Players, as: FormatPlayers
  alias Game.Hint
  alias Game.Player
  alias Game.Session
  alias Game.Session.Channels
  alias Game.Session.Character, as: SessionCharacter
  alias Game.Session.Commands
  alias Game.Session.Effects
  alias Game.Session.Help
  alias Game.Session.GMCP
  alias Game.Session.Regen
  alias Game.Session.SessionStats
  alias Game.Session.State
  alias Game.Socket
  alias Game.World.Master, as: WorldMaster
  alias Metrics.PlayerInstrumenter

  @save_period 15_000
  @force_disconnect_period 5_000
  @heartbeat_timeout 60_000

  @timeout_check 5000
  @timeout_seconds Keyword.get(Application.compile_env(:ex_venture, :game, []), :timeout_seconds)

  #
  # GenServer callbacks
  #

  @doc false
  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  def init([socket]) do
    Logger.info("New session started #{inspect(self())}", type: :session)
    state = clean_state(socket)
    Session.Registry.register_connection(state.id)
    send(self(), :start)
    {:ok, state}
  end

  def init([socket, player_id]) do
    send(self(), {:recover_session, player_id})
    PlayerInstrumenter.session_recovered()
    Logger.info("Session recovering (#{player_id}) - #{inspect(self())}", type: :session)
    {:ok, clean_state(socket)}
  end

  defp clean_state(socket) do
    now = Timex.now()

    %State{
      id: UUID.uuid4(),
      socket: socket,
      state: "login",
      session_started_at: now,
      last_recv: now,
      idle: Help.init_idle(now),
      mode: "commands",
      target: nil,
      is_targeting: MapSet.new(),
      regen: %{is_regenerating: false, count: 0},
      reply_to: nil,
      commands: %{},
      skills: %{},
      stats: %SessionStats{},
      is_afk: false
    }
  end

  # On a disconnect unregister the PID and stop the server
  def handle_cast(:disconnect, state = %{state: "login"}) do
    Logger.info(fn -> "Disconnecting the session" end, type: :session)
    {:stop, :normal, state}
  end

  def handle_cast(:disconnect, state = %{state: "create"}) do
    Logger.info(fn -> "Disconnecting the session" end, type: :session)
    {:stop, :normal, state}
  end

  def handle_cast(:disconnect, state = %{state: "active"}) do
    Logger.info(fn -> "Disconnecting the session" end, type: :session)
    %{save: save, session_started_at: session_started_at, stats: stats} = state

    Session.Registry.unregister()
    Session.Registry.player_offline(state.character)

    Environment.leave(save.room_id, state.character, :signout)
    Environment.unlink(save.room_id)

    Account.save_session(
      state.user,
      state.character,
      save,
      session_started_at,
      Timex.now(),
      stats
    )

    {:stop, :normal, state}
  end

  def handle_cast(:disconnect, state) do
    Logger.info(fn -> "Disconnecting the session - Fall through" end, type: :session)
    {:stop, :normal, state}
  end

  def handle_cast({:disconnect, opts}, state) when is_list(opts) do
    case Keyword.get(opts, :reason) do
      "server shutdown" ->
        state |> Socket.echo("The server will be shutting down shortly.")

      _ ->
        state |> Socket.echo("You are being signed out.\nGood bye.")
    end

    Task.start(fn ->
      Process.sleep(@force_disconnect_period)
      state |> Socket.disconnect()
    end)

    {:noreply, state}
  end

  # forward the echo the socket pid
  def handle_cast({:echo, message}, state) do
    state |> Socket.echo(message)
    {:noreply, state}
  end

  # Handle logging in
  def handle_cast({:recv, name}, state = %{state: "login"}) do
    state = Session.Login.process(name, state)
    {:noreply, Map.merge(state, %{last_recv: Timex.now()})}
  end

  # Handle displaying message after signing in
  def handle_cast({:recv, _name}, state = %{state: "after_sign_in"}) do
    state = Session.Login.after_sign_in(state, self())
    send(self(), :regen)
    {:noreply, Map.merge(state, %{last_recv: Timex.now()})}
  end

  # Handle creating an account
  def handle_cast({:recv, name}, state = %{state: "create"}) do
    state = Session.CreateAccount.process(name, state)
    {:noreply, Map.merge(state, %{last_recv: Timex.now()})}
  end

  def handle_cast({:recv, message}, state = %{state: "active", mode: "commands"}) do
    state |> Commands.process_command(message)
  end

  def handle_cast({:recv, message}, state = %{state: "active", mode: "paginate"}) do
    {:noreply, Pager.paginate(state, command: message, lines: state.save.config.pager_size)}
  end

  def handle_cast({:recv, _message}, state = %{state: "active", mode: "continuing"}) do
    {:noreply, state}
  end

  def handle_cast({:recv, ""}, state = %{state: "active", mode: "editor"}) do
    case state.editor_module.editor(:complete, state) do
      {:update, state} ->
        state =
          state
          |> Map.put(:mode, "commands")
          |> Map.delete(:editor_module)

        state |> prompt()
        {:noreply, Map.put(state, :mode, "commands")}
    end
  end

  def handle_cast({:recv, line}, state = %{state: "active", mode: "editor"}) do
    case state.editor_module.editor({:text, line}, state) do
      {:update, state} ->
        {:noreply, state}
    end
  end

  def handle_cast({:recv_gmcp, module, data}, state) do
    case GMCP.handle_gmcp(state, module, data) do
      :ok ->
        {:noreply, state}

      {:update, state} ->
        {:noreply, state}
    end
  end

  def handle_cast({:teleport, room_id}, state) do
    {:update, state} = Move.move_to(state, room_id, :teleport, :teleport)
    state |> prompt()
    {:noreply, state}
  end

  # Handle logging in from the web client
  def handle_cast({:sign_in, character_id}, state = %{state: "login"}) do
    state = Session.Login.sign_in(character_id, state)
    {:noreply, state}
  end

  #
  # Character callbacks
  #

  def handle_cast({:targeted, player}, state) do
    {:noreply, SessionCharacter.targeted(state, player)}
  end

  def handle_cast({:apply_effects, effects, from, description}, state = %{state: "active"}) do
    {:noreply, SessionCharacter.apply_effects(state, effects, from, description)}
  end

  def handle_cast({:effects_applied, effects, target}, state = %{state: "active"}) do
    {:noreply, SessionCharacter.effects_applied(state, effects, target)}
  end

  def handle_cast({:notify, event}, state) do
    {:noreply, SessionCharacter.notify(state, event)}
  end

  def handle_call(:info, _from, state) do
    {:reply, Character.to_simple(state.character), state}
  end

  #
  # Channels
  #

  def handle_info({:channel, {:joined, channel}}, state) do
    {:noreply, Channels.joined(state, channel)}
  end

  def handle_info({:channel, {:left, channel}}, state) do
    {:noreply, Channels.left(state, channel)}
  end

  def handle_info({:channel, {:broadcast, channel, message}}, state) do
    {:noreply, Channels.broadcast(state, channel, message)}
  end

  def handle_info({:channel, {:tell, from, message}}, state) do
    {:noreply, Channels.tell(state, from, message)}
  end

  #
  # General callback
  #

  def handle_info(:start, state) do
    case WorldMaster.is_world_online?() do
      true ->
        state |> Session.Login.start()

      false ->
        state |> Socket.echo("The world is not online yet. Please try again shortly.")
        self() |> Process.send_after({:disconnect, :world_not_alive}, 750)
    end

    {:noreply, state}
  end

  def handle_info({:authorize, character}, state) do
    state = Session.Login.sign_in(character.id, state)
    {:noreply, state}
  end

  def handle_info({:disconnect, :world_not_alive}, state) do
    state |> Socket.disconnect()
    {:noreply, state}
  end

  def handle_info({:recover_session, user_id}, state) do
    state = Session.Login.recover_session(user_id, state)
    self() |> schedule_save()
    self() |> schedule_inactive_check()
    self() |> schedule_heartbeat()

    {:noreply, state}
  end

  def handle_info(:regen, state = %{save: _save}) do
    {:noreply, Regen.tick(state)}
  end

  def handle_info({:continue, command}, state) do
    command |> Commands.run_command(state)
  end

  def handle_info(:save, state = %{state: "active"}) do
    %{save: save, session_started_at: session_started_at} = state
    state.character |> Account.save(save)
    state.character |> Account.update_time_online(session_started_at, Timex.now())
    self() |> schedule_save()
    {:noreply, state}
  end

  def handle_info(:save, state) do
    self() |> schedule_save()
    {:noreply, state}
  end

  def handle_info(:inactive_check, state) do
    {:noreply, check_for_inactive(state)}
  end

  def handle_info(:heartbeat, state) do
    state |> GMCP.heartbeat()
    state |> Socket.nop()
    self() |> schedule_heartbeat()
    {:noreply, state}
  end

  def handle_info({:continuous_effect, effect_id}, state) do
    Logger.debug(
      fn ->
        "Processing effect (#{effect_id})"
      end,
      type: :player
    )

    state =
      state
      |> Effects.handle_continuous_effect(effect_id)
      |> Regen.maybe_trigger_regen()

    {:noreply, state}
  end

  def handle_info({:continuous_effect, :clear, effect_id}, state) do
    Logger.debug(
      fn ->
        "Clearing effect (#{effect_id})"
      end,
      type: :player
    )

    state = Character.Effects.clear_continuous_effect(state, effect_id)
    {:noreply, state}
  end

  def handle_info({:skill, :ready, skill}, state) do
    state |> Socket.echo("#{Format.skill_name(skill)} is ready.")
    state |> GMCP.skill_state(skill, active: true)
    skills = Map.delete(state.skills, skill.id)
    state = Map.put(state, :skills, skills)
    {:noreply, state}
  end

  def handle_info({:resurrect, graveyard_id}, state) do
    %{save: %{stats: stats}} = state

    case stats.health_points do
      health_points when health_points < 1 ->
        stats = Map.put(stats, :health_points, 1)
        save = %{state.save | stats: stats}

        state =
          state
          |> Player.update_save(save)
          |> Regen.maybe_trigger_regen()

        {:update, state} = Move.move_to(state, graveyard_id, :death, :respawn)
        state |> prompt()

        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  @doc """
  Send the prompt to the user's socket
  """
  def prompt(state) do
    state |> GMCP.vitals()
    state |> Socket.prompt(FormatPlayers.prompt(state.save))
    state
  end

  # Schedule an inactive check
  def schedule_inactive_check(pid) do
    :erlang.send_after(@timeout_check, pid, :inactive_check)
  end

  # Schedule a save
  def schedule_save(pid) do
    :erlang.send_after(@save_period, pid, :save)
  end

  # Schedule a heartbeat
  def schedule_heartbeat(pid) do
    :erlang.send_after(@heartbeat_timeout, pid, :heartbeat)
  end

  # Check if the session is inactive, disconnect if it is
  defp check_for_inactive(state = %{is_afk: true}) do
    self() |> schedule_inactive_check()

    state
  end

  defp check_for_inactive(state = %{last_recv: last_recv}) do
    self() |> schedule_inactive_check()

    {:ok, state} = state |> Help.maybe_display_hints()

    case Timex.diff(Timex.now(), last_recv, :seconds) do
      time when time > @timeout_seconds ->
        Logger.info("Idle player #{inspect(self())} - setting afk", type: :session)

        state = %{state | is_afk: true}
        Session.Registry.update(%{state.character | save: state.save}, state)

        message = "You seem to be idle, setting you to {command}AFK{/command}."
        state |> Socket.echo(message)

        Hint.gate(state, "afk.started")

        state

      _ ->
        state
    end
  end
end
