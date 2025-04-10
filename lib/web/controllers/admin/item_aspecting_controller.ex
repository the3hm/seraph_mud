defmodule Web.Admin.ItemAspectingController do
  @moduledoc """
  Admin controller for managing aspects attached to items.
  Handles attaching and removing item aspects.
  """

  use Web.AdminController

  alias Web.Item
  alias Web.ItemAspect
  alias Web.ItemAspecting
  alias Web.Router.Helpers, as: Routes

  @doc """
  Render form for assigning a new aspect to an item.
  """
  def new(conn, %{"item_id" => item_id}) do
    item = Item.get(item_id)
    changeset = ItemAspecting.new(item)

    render(conn, "new.html",
      item: item,
      item_aspects: ItemAspect.all(),
      changeset: changeset
    )
  end

  @doc """
  Attach an aspect to an item.
  """
  def create(conn, %{"item_id" => item_id, "item_aspecting" => params}) do
    item = Item.get(item_id)

    case ItemAspecting.create(item, params) do
      {:ok, item_aspecting} ->
        conn
        |> put_flash(:info, "Added the aspect to #{item.name}!")
        |> redirect(to: Routes.item_path(conn, :show, item_aspecting.item_id))

      {:error, changeset} ->
        render(conn, "new.html",
          item: item,
          item_aspects: ItemAspect.all(),
          changeset: changeset,
          error: "There was an issue adding the aspect to #{item.name}. Please try again."
        )
    end
  end

  @doc """
  Remove an attached aspect from an item.
  """
  def delete(conn, %{"id" => id}) do
    item_aspect = ItemAspecting.get(id)

    case ItemAspecting.delete(item_aspect) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Aspect removed from the item.")
        |> redirect(to: Routes.item_path(conn, :show, item_aspect.item_id))

      _ ->
        conn
        |> put_flash(:error, "There was an issue removing the aspect. Please try again.")
        |> redirect(to: Routes.item_path(conn, :show, item_aspect.item_id))
    end
  end
end
