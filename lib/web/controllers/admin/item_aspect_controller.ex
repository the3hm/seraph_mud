defmodule Web.Admin.ItemAspectController do
  @moduledoc """
  Admin controller for managing item aspects.

  Provides actions to list, view, create, edit, and update aspects that can be attached to items.
  """

  use Web.AdminController

  alias Web.ItemAspect
  alias Web.Router.Helpers, as: Routes

  @doc """
  List all item aspects.
  """
  def index(conn, _params) do
    render(conn, "index.html", item_aspects: ItemAspect.all())
  end

  @doc """
  Show a single item aspect.
  """
  def show(conn, %{"id" => id}) do
    item_aspect = ItemAspect.get(id)

    render(conn, "show.html", item_aspect: item_aspect)
  end

  @doc """
  Render form for creating a new item aspect.
  """
  def new(conn, _params) do
    render(conn, "new.html", changeset: ItemAspect.new())
  end

  @doc """
  Create a new item aspect.
  """
  def create(conn, %{"item_aspect" => params}) do
    case ItemAspect.create(params) do
      {:ok, item_aspect} ->
        conn
        |> put_flash(:info, "Created #{item_aspect.name}!")
        |> redirect(to: Routes.item_aspect_path(conn, :show, item_aspect.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the item aspect. Please try again.")
        |> render("new.html", changeset: changeset)
    end
  end

  @doc """
  Render form for editing an item aspect.
  """
  def edit(conn, %{"id" => id}) do
    item_aspect = ItemAspect.get(id)
    changeset = ItemAspect.edit(item_aspect)

    render(conn, "edit.html",
      item_aspect: item_aspect,
      changeset: changeset
    )
  end

  @doc """
  Update an existing item aspect.
  """
  def update(conn, %{"id" => id, "item_aspect" => params}) do
    case ItemAspect.update(id, params) do
      {:ok, item_aspect} ->
        conn
        |> put_flash(:info, "#{item_aspect.name} updated!")
        |> redirect(to: Routes.item_aspect_path(conn, :show, item_aspect.id))

      {:error, changeset} ->
        item_aspect = ItemAspect.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{item_aspect.name}. Please try again.")
        |> render("edit.html",
          item_aspect: item_aspect,
          changeset: changeset
        )
    end
  end
end
