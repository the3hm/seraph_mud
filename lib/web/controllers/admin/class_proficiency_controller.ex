defmodule Web.Admin.ClassProficiencyController do
  @moduledoc """
  Admin controller for managing proficiencies associated with a character class.
  """

  use Web.AdminController

  alias Web.Class
  alias Web.Proficiency

  @doc """
  Displays a form to assign a new proficiency to a class.
  """
  def new(conn, %{"class_id" => class_id}) do
    class = Class.get(class_id)
    changeset = Class.new_class_proficiency(class)
    proficiencies = Proficiency.all()

    render(conn, :new,
      class: class,
      proficiencies: proficiencies,
      changeset: changeset
    )
  end

  @doc """
  Adds a proficiency to the class.
  """
  def create(conn, %{"class_id" => class_id, "class_proficiency" => params}) do
    class = Class.get(class_id)

    case Class.add_proficiency(class, params) do
      {:ok, _class_proficiency} ->
        redirect(conn,
          to: ~p"/admin/classes/#{class.id}",
          flash: [info: "Proficiency added to #{class.name}"]
        )

      {:error, changeset} ->
        proficiencies = Proficiency.all()

        render(conn, :new,
          class: class,
          proficiencies: proficiencies,
          changeset: changeset,
          error_flash: "There was an issue adding the proficiency"
        )
    end
  end

  @doc """
  Removes a proficiency from a class.
  """
  def delete(conn, %{"id" => id}) do
    case Class.remove_proficiency(id) do
      {:ok, class_proficiency} ->
        redirect(conn,
          to: ~p"/admin/classes/#{class_proficiency.class_id}",
          flash: [info: "Proficiency removed"]
        )

      _ ->
        redirect(conn,
          to: ~p"/admin/dashboard",
          flash: [error: "There was a problem removing the proficiency"]
        )
    end
  end
end
