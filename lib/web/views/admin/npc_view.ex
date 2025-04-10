defmodule Web.Admin.NPCView do
  @moduledoc """
  View helpers for Admin NPC
  """

  use Web, :view
  use Game.Currency

  alias Data.Stats
  alias Game.Config
  alias Game.Skills
  alias Web.Admin.SharedView
  alias Web.Zone

  import Ecto.Changeset

  @doc """
  Return the pretty-printed JSON stats
  """
  def stats(changeset) do
    case get_field(changeset, :stats) do
      nil ->
        Config.basic_stats()
        |> Jason.encode!()
        |> Jason.Formatter.pretty_print()

      stats ->
        stats
        |> Stats.default()
        |> Jason.encode!()
        |> Jason.Formatter.pretty_print()
    end
  end

  @doc """
  Return comma-separated tags
  """
  def tags(changeset) do
    case get_field(changeset, :tags) do
      nil -> ""
      tags -> Enum.join(tags, ", ")
    end
  end

  @doc """
  Check if the NPC has a custom name set
  """
  def custom_name?(%{name: name}) do
    name != "" && !is_nil(name)
  end

  @doc """
  Load trainable skills for display
  """
  def skills(npc) do
    Skills.skills(npc.trainable_skills)
  end

  @doc """
  Human-friendly display name for stat keys
  """
  def stat_display_name(stat) do
    stat
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
