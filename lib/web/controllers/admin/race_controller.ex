defmodule Web.Admin.RaceController do
  @moduledoc """
  Admin controller for managing races in the game.
  """

  use Web.AdminController

  alias Web.Race
  alias Web.Router.Helpers, as: Routes

  @doc """
  Lists all available races.
  """
  def index(conn, _params) do
    render(conn, "index.html", races: Race.all())
  end

  @doc """
  Shows a single race with details and options.
  """
  def show(conn, %{"id" => id}) do
    render(conn, "show.html", race: Race.get(id))
  end

  @doc """
  Renders the new race form.
  """
  def new(conn, _params) do
    render(conn, "new.html", changeset: Race.new())
  end

  @doc """
  Creates a new race entry.
  """
  def create(conn, %{"race" => params}) do
    case Race.create(params) do
      {:ok, race} ->
        conn
        |> put_flash(:info, "#{race.name} created!")
        |> redirect(to: Routes.admin_race_path(conn, :show, race.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the race. Please try again.")
        |> render("new.html", changeset: changeset)
    end
  end

  @doc """
  Renders the edit form for a race.
  """
  def edit(conn, %{"id" => id}) do
    race = Race.get(id)
    render(conn, "edit.html", race: race, changeset: Race.edit(race))
  end

  @doc """
  Updates an existing race with new data.
  """
  def update(conn, %{"id" => id, "race" => params}) do
    case Race.update(id, params) do
      {:ok, race} ->
        conn
        |> put_flash(:info, "#{race.name} updated!")
        |> redirect(to: Routes.admin_race_path(conn, :show, race.id))

      {:error, changeset} ->
        race = Race.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{race.name}. Please try again.")
        |> render("edit.html", race: race, changeset: changeset)
    end
  end
end
