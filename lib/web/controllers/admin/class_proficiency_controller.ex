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

    conn
    |> assign(:class, class)
    |> assign(:proficiencies, proficiencies)
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  @doc """
  Adds a proficiency to the class.
  """
  def create(conn, %{"class_id" => class_id, "class_proficiency" => params}) do
    class = Class.get(class_id)

    case Class.add_proficiency(class, params) do
      {:ok, _class_proficiency} ->
        conn
        |> put_flash(:info, "Proficiency added to #{class.name}")
        |> redirect(to: class_path(conn, :show, class.id))

      {:error, changeset} ->
        proficiencies = Proficiency.all()

        conn
        |> put_flash(:error, "There was an issue adding the proficiency")
        |> assign(:class, class)
        |> assign(:proficiencies, proficiencies)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  @doc """
  Removes a proficiency from a class.
  """
  def delete(conn, %{"id" => id}) do
    case Class.remove_proficiency(id) do
      {:ok, class_proficiency} ->
        conn
        |> put_flash(:info, "Proficiency removed")
        |> redirect(to: class_path(conn, :show, class_proficiency.class_id))

      _ ->
        conn
        |> put_flash(:error, "There was a problem removing the proficiency")
        |> redirect(to: dashboard_path(conn, :index))
    end
  end
end
