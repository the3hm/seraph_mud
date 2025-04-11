defmodule Web.Admin.SkillController do
  @moduledoc """
  Admin controller for managing skills.
  Includes pagination, filtering, creation, and editing of skill entries.
  """

  use Web.AdminController

  alias Web.Router.Helpers, as: Routes
  alias Web.Skill

  plug(Web.Plug.FetchPage when action in [:index])

  @doc """
  Lists all skills with optional filters.
  """
  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "skill", %{})

    %{page: skills, pagination: pagination} =
      Skill.all(filter: filter, page: page, per: per)

    render(conn, "index.html",
      skills: skills,
      filter: filter,
      pagination: pagination
    )
  end

  @doc """
  Displays a single skill.
  """
  def show(conn, %{"id" => id}) do
    render(conn, "show.html", skill: Skill.get(id))
  end

  @doc """
  Renders the form to create a new skill.
  """
  def new(conn, _params) do
    render(conn, "new.html", changeset: Skill.new())
  end

  @doc """
  Creates a new skill entry.
  """
  def create(conn, %{"skill" => params}) do
    case Skill.create(params) do
      {:ok, skill} ->
        conn
        |> put_flash(:info, "#{skill.name} added!")
        |> redirect(to: Routes.admin_skill_path(conn, :show, skill.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the skill. Please try again.")
        |> render("new.html", changeset: changeset)
    end
  end

  @doc """
  Renders the form to edit a skill.
  """
  def edit(conn, %{"id" => id}) do
    skill = Skill.get(id)

    render(conn, "edit.html",
      skill: skill,
      changeset: Skill.edit(skill)
    )
  end

  @doc """
  Updates a skill entry with new data.
  """
  def update(conn, %{"id" => id, "skill" => params}) do
    case Skill.update(id, params) do
      {:ok, skill} ->
        conn
        |> put_flash(:info, "#{skill.name} updated!")
        |> redirect(to: Routes.admin_skill_path(conn, :show, skill.id))

      {:error, changeset} ->
        skill = Skill.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{skill.name}. Please try again.")
        |> render("edit.html",
          skill: skill,
          changeset: changeset
        )
    end
  end
end
