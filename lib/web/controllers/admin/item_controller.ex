defmodule Web.Admin.ItemController do
  @moduledoc """
  Admin controller for managing in-game items.
  Supports listing, viewing, editing, cloning, and creating new items.
  """

  use Web.AdminController

  alias Web.Item
  alias Web.Router.Helpers, as: Routes

  plug Web.Plug.FetchPage when action in [:index]

  @doc """
  List all items with optional filters and pagination.
  """
  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "item", %{})
    %{page: items, pagination: pagination} = Item.all(filter: filter, page: page, per: per)

    render(conn, "index.html",
      items: items,
      filter: filter,
      pagination: pagination
    )
  end

  @doc """
  Show a single item along with its compiled representation.
  """
  def show(conn, %{"id" => id}) do
    item = Item.get(id)
    compiled_item = Data.Item.compile(item)

    render(conn, "show.html",
      item: item,
      compiled_item: compiled_item
    )
  end

  @doc """
  Render the item edit form.
  """
  def edit(conn, %{"id" => id}) do
    item = Item.get(id)
    changeset = Item.edit(item)

    render(conn, "edit.html",
      item: item,
      changeset: changeset
    )
  end

  @doc """
  Update an existing item.
  """
  def update(conn, %{"id" => id, "item" => params}) do
    case Item.update(id, params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "#{item.name} updated!")
        |> redirect(to: Routes.item_path(conn, :show, item.id))

      {:error, changeset} ->
        item = Item.get(id)

        conn
        |> put_flash(:error, "There was a problem updating #{item.name}. Please try again.")
        |> render("edit.html",
          item: item,
          changeset: changeset
        )
    end
  end

  @doc """
  Render the new item form, optionally cloning from an existing item.
  """
  def new(conn, %{"clone_id" => clone_id}) do
    clone = clone_id |> Item.get() |> Item.clone()
    changeset = Item.edit(clone)

    render(conn, "new.html", changeset: changeset)
  end

  def new(conn, _params) do
    changeset = Item.new()

    render(conn, "new.html", changeset: changeset)
  end

  @doc """
  Handle creation of a new item.
  """
  def create(conn, %{"item" => params}) do
    case Item.create(params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "#{item.name} created!")
        |> redirect(to: Routes.item_path(conn, :show, item.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the item. Please try again.")
        |> render("new.html", changeset: changeset)
    end
  end
end
