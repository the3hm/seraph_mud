defmodule Game.Command.Crash do
  @moduledoc """
  The "crash" command
  """

  use Game.Command

  @required_flags ["admin"]

  @zone Application.compile_env(:ex_venture, :game, [])[:zone]

  commands(["crash"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Crash"
  def help(:short), do: "Crash various processes in the game"

  def help(:full) do
    """
    #{help(:short)}.

    Crash the room process you are in:
    [ ] > {command}crash room{/command}

    Crash the zone process you are in:
    [ ] > {command}crash zone{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Crash.parse("crash room")
      {:room}

      iex> Game.Command.Crash.parse("crash zone")
      {:zone}

      iex> Game.Command.Crash.parse("crash")
      {:error, :bad_parse, "crash"}

      iex> Game.Command.Crash.parse("crash extra")
      {:error, :bad_parse, "crash extra"}

      iex> Game.Command.Crash.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("crash room"), do: {:room}
  def parse("crash zone"), do: {:zone}
  def parse(command), do: {:error, :bad_parse, command}

  @impl Game.Command
  @doc """
  Crash the requested process
  """
  def run(command, state)

  def run({:room}, %{user: user, save: save} = state) do
    if "admin" in user.flags do
      Environment.crash(save.room_id)
      state |> Socket.echo("Sent a message to crash the room.")
    else
      state |> Socket.echo("You must be an admin to perform this.")
    end
  end

  def run({:zone}, %{user: user, save: save} = state) do
    if "admin" in user.flags do
      {:ok, room} = Environment.look(save.room_id)
      @zone.crash(room.zone_id)
      state |> Socket.echo("Sent a message to crash the zone.")
    else
      state |> Socket.echo("You must be an admin to perform this.")
    end
  end
end
