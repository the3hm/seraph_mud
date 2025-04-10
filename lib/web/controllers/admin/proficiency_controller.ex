defmodule Web.Admin.ProficiencyController do
  @moduledoc """
  Admin controller for managing proficiencies.
  """

  use Web.AdminController

  plug :ensure_admin!

  alias Web.Proficiency
  alias Web.Router.Helpers, as: Routes

  @doc """
  Lists all proficiencies.
  """
  def index(conn, _params) do
    render(conn, "index.html", proficiencies: Proficiency.all())
  end

  @doc """
  Displays a single proficiency by ID.
  """
  def show(conn, %{"id" => id}) do
    with {:ok, proficiency} <- Proficiency.get(id) do
      render(conn, "show.html", proficiency: proficiency)
    else
      _ ->
        conn
        |> put_flash(:error, "Proficiency not found.")
        |> redirect(to: Routes.admin_proficiency_path(conn, :index))
    end
  end

  @doc """
  Renders form for creating a new proficiency.
  """
  def new(conn, _params) do
    render(conn, "new.html", changeset: Proficiency.new())
  end

  @doc """
  Handles creation of a new proficiency.
  """
  def create(conn, %{"proficiency" => params}) do
    case Proficiency.create(params) do
      {:ok, proficiency} ->
        conn
        |> put_flash(:info, "#{proficiency.name} created!")
        |> redirect(to: Routes.admin_proficiency_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the proficiency. Please try again.")
        |> render("new.html", changeset: changeset)
    end
  end

  @doc """
  Renders the edit form for a proficiency.
  """
  def edit(conn, %{"id" => id}) do
    with {:ok, proficiency} <- Proficiency.get(id) do
      render(conn, "edit.html",
        proficiency: proficiency,
        changeset: Proficiency.edit(proficiency)
      )
    else
      _ ->
        conn
        |> put_flash(:error, "Proficiency not found.")
        |> redirect(to: Routes.admin_proficiency_path(conn, :index))
    end
  end

  @doc """
  Updates an existing proficiency.
  """
  def update(conn, %{"id" => id, "proficiency" => params}) do
    with {:ok, proficiency} <- Proficiency.get(id),
         {:ok, updated} <- Proficiency.update(proficiency, params) do
      conn
      |> put_flash(:info, "#{updated.name} updated!")
      |> redirect(to: Routes.admin_proficiency_path(conn, :index))

    else
      {:ok, proficiency}, {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue updating #{proficiency.name}. Please try again.")
        |> render("edit.html", proficiency: proficiency, changeset: changeset)

      _ ->
        conn
        |> put_flash(:error, "Proficiency not found.")
        |> redirect(to: Routes.admin_proficiency_path(conn, :index))
    end
  end
end
