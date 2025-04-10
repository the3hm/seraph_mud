defmodule Web.Admin.ConfigView do
  use Web, :view

  alias Ecto.Changeset
  alias Game.Config

  def name("after_sign_in_message"), do: "After Sign In Message"
  def name("basic_stats"), do: "Basic Stats"
  def name("character_names"), do: "Random Character Names"
  def name("description"), do: "Description"
  def name("discord_client_id"), do: "Discord Client ID"
  def name("discord_invite_url"), do: "Discord Invite URL"
  def name("game_name"), do: "Game Name"
  def name("game_short_name"), do: "Game Short Name"
  def name("grapevine_only_login"), do: "Grapevine Only Login?"
  def name("motd"), do: "Message of the Day"
  def name("starting_room_ids"), do: "Starting Room IDs"
  def name("starting_save"), do: "Starting Save"

  def basic_stats_value(changeset) do
    changeset
    |> Changeset.get_field(:value, Config.basic_stats())
    |> Jason.decode!()
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
  end

  def starting_save_value(changeset) do
    changeset
    |> Changeset.get_field(:value)
    |> Jason.decode!()
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
  end
end
