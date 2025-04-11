defmodule Web.Admin.ProficiencyController do
  @moduledoc """
  Admin controller for managing proficiencies.
  """

  use Web.AdminController

  plug(:ensure_admin!)

  alias Web.Proficiency

  @doc """
  Lists all proficiencies.
  """
  def index(conn, _params) do
    render(conn, :index, proficiencies: Proficiency.all())
  end

  @doc """
  Displays a single proficiency by ID.
  """
  def show(conn, %{"id" => id}) do
    with {:ok, proficiency} <- Proficiency.get(id) do
      render(conn, :show, proficiency: proficiency)
    else
      _ ->
        redirect(conn,
          to: ~p"/admin/proficiencies",
          flash: [error: "Proficiency not found."]
        )
    end
  end

  @doc """
  Renders form for creating a new proficiency.
  """
  def new(conn, _params) do
    render(conn, :new, changeset: Proficiency.new())
  end

  @doc """
  Handles creation of a new proficiency.
  """
  def create(conn, %{"proficiency" => params}) do
    case Proficiency.create(params) do
      {:ok, proficiency} ->
        redirect(conn,
          to: ~p"/admin/proficiencies",
          flash: [info: "#{proficiency.name} created!"]
        )

      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          error_flash: "There was an issue creating the proficiency. Please try again."
        )
    end
  end

  @doc """
  Renders the edit form for a proficiency.
  """
  def edit(conn, %{"id" => id}) do
    with {:ok, proficiency} <- Proficiency.get(id) do
      render(conn, :edit,
        proficiency: proficiency,
        changeset: Proficiency.edit(proficiency)
      )
    else
      _ ->
        redirect(conn,
          to: ~p"/admin/proficiencies",
          flash: [error: "Proficiency not found."]
        )
    end
  end

  @doc """
  Updates an existing proficiency.
  """
  def update(conn, %{"id" => id, "proficiency" => params}) do
    case Proficiency.get(id) do
      {:ok, proficiency} ->
        case Proficiency.update(proficiency, params) do
          {:ok, updated} ->
            redirect(conn,
              to: ~p"/admin/proficiencies",
              flash: [info: "#{updated.name} updated!"]
            )

          {:error, changeset} ->
            render(conn, :edit,
              proficiency: proficiency,
              changeset: changeset,
              error_flash: "There was an issue updating #{proficiency.name}. Please try again."
            )
        end

      _ ->
        redirect(conn,
          to: ~p"/admin/proficiencies",
          flash: [error: "Proficiency not found."]
        )
    end
  end
end
