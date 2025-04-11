defmodule Web.Admin.ItemAspectController do
  @moduledoc """
  Admin controller for managing item aspects.

  Provides actions to list, view, create, edit, and update aspects that can be attached to items.
  """

  use Web.AdminController

  alias Web.ItemAspect

  @doc """
  List all item aspects.
  """
  def index(conn, _params) do
    render(conn, :index, item_aspects: ItemAspect.all())
  end

  @doc """
  Show a single item aspect.
  """
  def show(conn, %{"id" => id}) do
    item_aspect = ItemAspect.get(id)
    render(conn, :show, item_aspect: item_aspect)
  end

  @doc """
  Render form for creating a new item aspect.
  """
  def new(conn, _params) do
    render(conn, :new, changeset: ItemAspect.new())
  end

  @doc """
  Create a new item aspect.
  """
  def create(conn, %{"item_aspect" => params}) do
    case ItemAspect.create(params) do
      {:ok, item_aspect} ->
        redirect(conn,
          to: ~p"/admin/item_aspects/#{item_aspect.id}",
          flash: [info: "Created #{item_aspect.name}!"]
        )

      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          error_flash: "There was an issue creating the item aspect. Please try again."
        )
    end
  end

  @doc """
  Render form for editing an item aspect.
  """
  def edit(conn, %{"id" => id}) do
    item_aspect = ItemAspect.get(id)
    render(conn, :edit, item_aspect: item_aspect, changeset: ItemAspect.edit(item_aspect))
  end

  @doc """
  Update an existing item aspect.
  """
  def update(conn, %{"id" => id, "item_aspect" => params}) do
    case ItemAspect.update(id, params) do
      {:ok, item_aspect} ->
        redirect(conn,
          to: ~p"/admin/item_aspects/#{item_aspect.id}",
          flash: [info: "#{item_aspect.name} updated!"]
        )

      {:error, changeset} ->
        item_aspect = ItemAspect.get(id)

        render(conn, :edit,
          item_aspect: item_aspect,
          changeset: changeset,
          error_flash: "There was an issue updating #{item_aspect.name}. Please try again."
        )
    end
  end
end
