defmodule Web.Admin.RaceController do
  @moduledoc """
  Admin controller for managing races in the game.
  """

  use Web.AdminController

  alias Web.Race

  @doc """
  Lists all available races.
  """
  def index(conn, _params) do
    render(conn, :index, races: Race.all())
  end

  @doc """
  Shows a single race with details and options.
  """
  def show(conn, %{"id" => id}) do
    render(conn, :show, race: Race.get(id))
  end

  @doc """
  Renders the new race form.
  """
  def new(conn, _params) do
    render(conn, :new, changeset: Race.new())
  end

  @doc """
  Creates a new race entry.
  """
  def create(conn, %{"race" => params}) do
    case Race.create(params) do
      {:ok, race} ->
        redirect(conn,
          to: ~p"/admin/races/#{race.id}",
          flash: [info: "#{race.name} created!"]
        )

      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          error_flash: "There was a problem creating the race. Please try again."
        )
    end
  end

  @doc """
  Renders the edit form for a race.
  """
  def edit(conn, %{"id" => id}) do
    race = Race.get(id)
    render(conn, :edit, race: race, changeset: Race.edit(race))
  end

  @doc """
  Updates an existing race with new data.
  """
  def update(conn, %{"id" => id, "race" => params}) do
    case Race.update(id, params) do
      {:ok, race} ->
        redirect(conn,
          to: ~p"/admin/races/#{race.id}",
          flash: [info: "#{race.name} updated!"]
        )

      {:error, changeset} ->
        race = Race.get(id)

        render(conn, :edit,
          race: race,
          changeset: changeset,
          error_flash: "There was an issue updating #{race.name}. Please try again."
        )
    end
  end
end
