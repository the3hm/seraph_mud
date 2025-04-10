defmodule Game.Environment do
  @moduledoc """
  Look at your surroundings, whether a room or an overworld
  """

  @environment Application.compile_env(:ex_venture, :game, [])[:environment]

  alias Game.Character

  @doc """
  Get the type of room based on its id
  """
  def room_type(room_id) do
    case room_id do
      "overworld:" <> _id -> :overworld
      _ -> :room
    end
  end

  def look(room_id), do: @environment.look(room_id)

  def enter(room_id, character, reason),
    do: @environment.enter(room_id, Character.to_simple(character), reason)

  def leave(room_id, character, reason),
    do: @environment.leave(room_id, Character.to_simple(character), reason)

  def notify(room_id, character, event),
    do: @environment.notify(room_id, character, event)

  def pick_up(room_id, item), do: @environment.pick_up(room_id, item)

  def pick_up_currency(room_id), do: @environment.pick_up_currency(room_id)

  def drop(room_id, character, item),
    do: @environment.drop(room_id, character, item)

  def drop_currency(room_id, character, currency),
    do: @environment.drop_currency(room_id, character, currency)

  def update_character(room_id, character),
    do: @environment.update_character(room_id, Character.to_simple(character))

  def link(room_id), do: @environment.link(room_id)

  def unlink(room_id), do: @environment.unlink(room_id)

  def crash(room_id), do: @environment.crash(room_id)
end
