defmodule Web.Admin.ShopItemController do
  @moduledoc """
  Admin controller for managing items inside shops.
  """

  use Web.AdminController

  alias Web.Router.Helpers, as: Routes
  alias Web.Item
  alias Web.Room
  alias Web.Shop

  @doc """
  Renders the form to add a new item to a shop.
  """
  def new(conn, %{"shop_id" => shop_id}) do
    shop = Shop.get(shop_id)
    room = Room.get(shop.room_id)

    render(conn, "new.html",
      items: Item.all(),
      shop: shop,
      room: room,
      changeset: Shop.new_item(shop)
    )
  end

  @doc """
  Creates a new shop item entry from the item and additional config.
  """
  def create(conn, %{"shop_id" => shop_id, "item" => %{"id" => item_id}, "shop_item" => params}) do
    shop = Shop.get(shop_id)
    item = Item.get(item_id)

    case Shop.add_item(shop, item, params) do
      {:ok, shop_item} ->
        conn
        |> put_flash(:info, "Item added to #{shop.name}!")
        |> redirect(to: Routes.admin_shop_path(conn, :show, shop_item.shop_id))

      {:error, changeset} ->
        room = Room.get(shop.room_id)

        render(conn, "new.html",
          items: Item.all(),
          shop: shop,
          room: room,
          changeset: changeset
        )
    end
  end

  @doc """
  Renders the edit form for an existing shop item.
  """
  def edit(conn, %{"id" => id}) do
    shop_item = Shop.get_item(id)
    shop = Shop.get(shop_item.shop_id)
    room = Room.get(shop.room_id)

    render(conn, "edit.html",
      items: Item.all(),
      shop_item: shop_item,
      shop: shop,
      room: room,
      changeset: Shop.edit_item(shop_item)
    )
  end

  @doc """
  Updates a shop item with new configuration or data.
  """
  def update(conn, %{"id" => id, "shop_item" => params}) do
    case Shop.update_item(id, params) do
      {:ok, shop_item} ->
        conn
        |> put_flash(:info, "Item updated!")
        |> redirect(to: Routes.admin_shop_path(conn, :show, shop_item.shop_id))

      {:error, changeset} ->
        shop_item = Shop.get_item(id)
        shop = Shop.get(shop_item.shop_id)
        room = Room.get(shop.room_id)

        render(conn, "edit.html",
          items: Item.all(),
          shop_item: shop_item,
          shop: shop,
          room: room,
          changeset: changeset
        )
    end
  end

  @doc """
  Deletes a shop item.
  """
  def delete(conn, %{"id" => id}) do
    case Shop.delete_item(id) do
      {:ok, shop_item} ->
        conn
        |> put_flash(:info, "Item deleted!")
        |> redirect(to: Routes.admin_shop_path(conn, :show, shop_item.shop_id))

      _ ->
        conn
        |> put_flash(:error, "There was an issue deleting the item from the shop. Please try again.")
        |> redirect(to: Routes.admin_dashboard_path(conn, :index))
    end
  end
end
