defmodule Web.Admin.RaceView do
  @moduledoc """
  View helpers for Admin Race
  """

  use Web, :view

  alias Data.Stats
  alias Game.Config

  import Ecto.Changeset

  @doc """
  Pretty print the starting stats as JSON
  """
  def starting_stats(changeset) do
    case get_field(changeset, :starting_stats) do
      nil ->
        Config.basic_stats()
        |> Jason.encode!()
        |> Jason.Formatter.pretty_print()

      starting_stats ->
        starting_stats
        |> Stats.default()
        |> Jason.encode!()
        |> Jason.Formatter.pretty_print()
    end
  end
end
