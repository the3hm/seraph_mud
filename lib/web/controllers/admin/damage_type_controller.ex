defmodule Web.Admin.DamageTypeController do
  @moduledoc """
  Admin controller for managing damage types.
  """

  use Web.AdminController

  alias Web.DamageType

  @doc """
  Lists all damage types.
  """
  def index(conn, _params) do
    damage_types = DamageType.all()

    conn
    |> assign(:damage_types, damage_types)
    |> render("index.html")
  end

  @doc """
  Renders the form for creating a new damage type.
  """
  def new(conn, _params) do
    changeset = DamageType.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  @doc """
  Handles creation of a new damage type.
  """
  def create(conn, %{"damage_type" => params}) do
    case DamageType.create(params) do
      {:ok, damage_type} ->
        conn
        |> put_flash(:info, "#{damage_type.key} created!")
        |> redirect(to: damage_type_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the damage type. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  @doc """
  Renders the form for editing an existing damage type.
  """
  def edit(conn, %{"id" => id}) do
    damage_type = DamageType.get(id)
    changeset = DamageType.edit(damage_type)

    conn
    |> assign(:damage_type, damage_type)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  @doc """
  Handles update of a damage type.
  """
  def update(conn, %{"id" => id, "damage_type" => params}) do
    case DamageType.update(id, params) do
      {:ok, damage_type} ->
        conn
        |> put_flash(:info, "#{damage_type.key} updated!")
        |> redirect(to: damage_type_path(conn, :index))

      {:error, changeset} ->
        damage_type = DamageType.get(id)

        conn
        |> put_flash(:error, "There was a problem updating #{damage_type.key}. Please try again.")
        |> assign(:damage_type, damage_type)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
