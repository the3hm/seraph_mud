defmodule Game.NPC.Actions.CommandsMove do
  @moduledoc """
  Target a character
  """

  alias Data.Exit
  alias Game.Character
  alias Game.Door
  alias Game.Environment
  alias Game.Events.RoomEntered
  alias Game.NPC
  alias Game.NPC.Events
  alias Metrics.CharacterInstrumenter

  @npc_reaction_time_ms Application.compile_env(:ex_venture, [:npc, :reaction_time_ms], 300)

  @doc """
  Move to a new room
  """
  def act(state, action) do
    spawner = state.npc_spawner

    with {:ok, :conscious} <- check_conscious(state),
         {:ok, :no_target} <- check_no_target(state),
         {:ok, starting_room} <- Environment.look(spawner.room_id),
         {:ok, old_room} <- Environment.look(state.room_id),
         {:ok, room_exit, new_room} <- select_new_room(old_room),
         {:ok, :allowed} <- check_movement_allowed(action, starting_room, room_exit, new_room) do
      move_room(state, old_room, new_room, room_exit.direction)
    else
      _ -> {:ok, state}
    end
  end

  @doc """
  Check that the NPC is conscious before moving
  """
  def check_conscious(state) do
    if state.npc.stats.health_points > 0 do
      {:ok, :conscious}
    else
      {:error, :unconscious}
    end
  end

  @doc """
  Check that the NPC has no target before moving
  """
  def check_no_target(state) do
    if is_nil(state.target) do
      {:ok, :no_target}
    else
      {:error, :target}
    end
  end

  @doc """
  Select a random new room from the current room's exits
  """
  def select_new_room(room) do
    room_exit = Enum.random(room.exits)

    case Environment.look(room_exit.finish_id) do
      {:ok, room} -> {:ok, room_exit, room}
      error -> error
    end
  end

  def check_movement_allowed(action, old_room, room_exit, new_room) do
    if can_move?(action, old_room, room_exit, new_room) do
      {:ok, :allowed}
    else
      {:error, :blocked}
    end
  end

  def can_move?(action, old_room, room_exit, new_room) do
    no_door_or_open?(room_exit) &&
      under_maximum_move?(action.options, old_room, new_room) &&
      new_room.zone_id == old_room.zone_id
  end

  def no_door_or_open?(room_exit) do
    !(room_exit.has_door && Door.closed?(room_exit.door_id))
  end

  def move_room(state, old_room, new_room, direction) do
    CharacterInstrumenter.movement(:npc, fn ->
      npc = Character.to_simple(Events.npc(state))

      Environment.unlink(old_room.id)
      Environment.leave(old_room.id, npc, {:leave, direction})
      Environment.enter(new_room.id, npc, {:enter, Exit.opposite(direction)})
      Environment.link(old_room.id)

      Enum.each(new_room.players, fn player ->
        event = %RoomEntered{character: player}
        NPC.delay_notify(event, milliseconds: @npc_reaction_time_ms)
      end)
    end)

    {:ok, %{state | room_id: new_room.id}}
  end

  def under_maximum_move?(options, old_room, new_room) do
    max_distance = Map.get(options, :max_distance, 0)

    abs(old_room.x - new_room.x) <= max_distance &&
      abs(old_room.y - new_room.y) <= max_distance
  end
end
