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
    render(conn, :index, damage_types: DamageType.all())
  end

  @doc """
  Renders the form for creating a new damage type.
  """
  def new(conn, _params) do
    render(conn, :new, changeset: DamageType.new())
  end

  @doc """
  Handles creation of a new damage type.
  """
  def create(conn, %{"damage_type" => params}) do
    case DamageType.create(params) do
      {:ok, damage_type} ->
        redirect(conn,
          to: ~p"/admin/damage_types",
          flash: [info: "#{damage_type.key} created!"]
        )

      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          error_flash: "There was an issue creating the damage type. Please try again."
        )
    end
  end

  @doc """
  Renders the form for editing an existing damage type.
  """
  def edit(conn, %{"id" => id}) do
    damage_type = DamageType.get(id)

    render(conn, :edit,
      damage_type: damage_type,
      changeset: DamageType.edit(damage_type)
    )
  end

  @doc """
  Handles update of a damage type.
  """
  def update(conn, %{"id" => id, "damage_type" => params}) do
    case DamageType.update(id, params) do
      {:ok, damage_type} ->
        redirect(conn,
          to: ~p"/admin/damage_types",
          flash: [info: "#{damage_type.key} updated!"]
        )

      {:error, changeset} ->
        damage_type = DamageType.get(id)

        render(conn, :edit,
          damage_type: damage_type,
          changeset: changeset,
          error_flash: "There was a problem updating #{damage_type.key}. Please try again."
        )
    end
  end
end
