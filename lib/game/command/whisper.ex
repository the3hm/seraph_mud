defmodule Game.Command.Whisper do
  @moduledoc """
  The "whisper" command
  """

  use Game.Command

  import Game.Room.Helpers, only: [find_character: 3]

  alias Game.Character
  alias Game.Events.RoomOverheard
  alias Game.Events.RoomWhispered
  alias Game.Format.Channels, as: FormatChannels
  alias Game.Utility

  commands(["whisper"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Whisper"
  def help(:short), do: "Whisper to someone in the same room as you"

  def help(:full) do
    """
    Whisper to someone in the same room as you.

    Other players in the same room will be able to see that you are
    whispering to someone else.

    Example:
    [ ] > {command}whisper player hello{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Whisper.parse("whisper player text")
      {:whisper, "player text"}

      iex> Game.Command.Whisper.parse("whisper")
      {:error, :bad_parse, "whisper"}

      iex> Game.Command.Whisper.parse("unknown hi")
      {:error, :bad_parse, "unknown hi"}
  """
  @spec parse(String.t()) :: {atom}
  def parse(command)
  def parse("whisper " <> text), do: {:whisper, text}

  @impl Game.Command
  @doc """
  Send to all connected players
  """
  def run(command, state)

  def run({:whisper, who_and_message}, state = %{save: save}) do
    {:ok, room} = Environment.look(save.room_id)

    case find_character(room, who_and_message, message: true) do
      {:error, :not_found} ->
        message = "No character could be found matching your text."
        state |> Socket.echo(message)

      {:ok, character} ->
        player = Character.to_simple(state.character)

        message = Utility.strip_name(character, who_and_message)
        state |> Socket.echo(FormatChannels.send_whisper(character, message))

        message = Message.whisper(state.character, message)
        event = %RoomWhispered{character: player, message: message}
        Character.notify(character, event)

        message = FormatChannels.whisper_overheard(player, character)

        event = %RoomOverheard{
          character: player,
          characters: [player, character],
          message: message
        }

        Environment.notify(room.id, player, event)
    end

    :ok
  end
end
