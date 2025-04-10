defmodule Web.Admin.ClassSkillController do
  @moduledoc """
  Admin controller for assigning and removing skills from character classes.
  """

  use Web.AdminController

  alias Web.Class
  alias Web.Skill

  @doc """
  Displays a form to assign a new skill to a class.
  """
  def new(conn, %{"class_id" => class_id}) do
    class = Class.get(class_id)
    changeset = Class.new_class_skill(class)
    skills = Skill.all()

    conn
    |> assign(:class, class)
    |> assign(:skills, skills)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  @doc """
  Assigns a selected skill to a class.
  """
  def create(conn, %{"class_id" => class_id, "class_skill" => %{"skill_id" => skill_id}}) do
    class = Class.get(class_id)

    case Class.add_skill(class, skill_id) do
      {:ok, _class_skill} ->
        conn
        |> put_flash(:info, "Skill added to #{class.name}")
        |> redirect(to: class_path(conn, :show, class.id))

      {:error, changeset} ->
        skills = Skill.all()

        conn
        |> put_flash(:error, "There was an issue adding the skill")
        |> assign(:class, class)
        |> assign(:skills, skills)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  @doc """
  Removes a skill from a class.
  """
  def delete(conn, %{"id" => id}) do
    case Class.remove_skill(id) do
      {:ok, class_skill} ->
        conn
        |> put_flash(:info, "Skill removed")
        |> redirect(to: class_path(conn, :show, class_skill.class_id))

      _ ->
        conn
        |> put_flash(:error, "There was a problem removing the skill")
        |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
