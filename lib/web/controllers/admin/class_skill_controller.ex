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

    render(conn, :new,
      class: class,
      skills: skills,
      changeset: changeset
    )
  end

  @doc """
  Assigns a selected skill to a class.
  """
  def create(conn, %{"class_id" => class_id, "class_skill" => %{"skill_id" => skill_id}}) do
    class = Class.get(class_id)

    case Class.add_skill(class, skill_id) do
      {:ok, _class_skill} ->
        redirect(conn,
          to: ~p"/admin/classes/#{class.id}",
          flash: [info: "Skill added to #{class.name}"]
        )

      {:error, changeset} ->
        skills = Skill.all()

        render(conn, :new,
          class: class,
          skills: skills,
          changeset: changeset,
          error_flash: "There was an issue adding the skill"
        )
    end
  end

  @doc """
  Removes a skill from a class.
  """
  def delete(conn, %{"id" => id}) do
    case Class.remove_skill(id) do
      {:ok, class_skill} ->
        redirect(conn,
          to: ~p"/admin/classes/#{class_skill.class_id}",
          flash: [info: "Skill removed"]
        )

      _ ->
        redirect(conn,
          to: ~p"/admin/dashboard",
          flash: [error: "There was a problem removing the skill"]
        )
    end
  end
end
