defmodule Web.Admin.RaceSkillController do
  @moduledoc """
  Admin controller for managing skills associated with a specific race.
  """

  use Web.AdminController

  alias Web.Race
  alias Web.Skill

  @doc """
  Renders the form to add a new skill to a race.
  """
  def new(conn, %{"race_id" => race_id}) do
    race = Race.get(race_id)

    render(conn, :new,
      race: race,
      skills: Skill.all(),
      changeset: Race.new_race_skill(race)
    )
  end

  @doc """
  Adds a skill to a race.
  """
  def create(conn, %{"race_id" => race_id, "race_skill" => %{"skill_id" => skill_id}}) do
    race = Race.get(race_id)

    case Race.add_skill(race, skill_id) do
      {:ok, _race_skill} ->
        redirect(conn,
          to: ~p"/admin/races/#{race.id}",
          flash: [info: "Skill added to #{race.name}!"]
        )

      {:error, changeset} ->
        render(conn, :new,
          race: race,
          skills: Skill.all(),
          changeset: changeset
        )
    end
  end

  @doc """
  Removes a skill from a race.
  """
  def delete(conn, %{"id" => id}) do
    case Race.remove_skill(id) do
      {:ok, race_skill} ->
        redirect(conn,
          to: ~p"/admin/races/#{race_skill.race_id}",
          flash: [info: "Skill removed from race."]
        )

      _ ->
        redirect(conn,
          to: ~p"/admin/dashboard",
          flash: [error: "There was an issue removing the skill. Please try again."]
        )
    end
  end
end
