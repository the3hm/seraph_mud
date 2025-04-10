defmodule Web.Admin.ShopController do
  @moduledoc """
  Admin controller for managing in-game shops associated with rooms.
  """

  use Web.AdminController

  alias Web.Router.Helpers, as: Routes
  alias Web.Room
  alias Web.Shop

  @doc """
  Displays a single shop along with its associated room.
  """
  def show(conn, %{"id" => id}) do
    shop = Shop.get(id)
    room = Room.get(shop.room_id)

    render(conn, "show.html",
      shop: shop,
      room: room
    )
  end

  @doc """
  Renders the new shop form for a given room.
  """
  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)

    render(conn, "new.html",
      room: room,
      changeset: Shop.new(room)
    )
  end

  @doc """
  Creates a new shop for the specified room.
  """
  def create(conn, %{"room_id" => room_id, "shop" => params}) do
    room = Room.get(room_id)

    case Shop.create(room, params) do
      {:ok, shop} ->
        conn
        |> put_flash(:info, "#{shop.name} created!")
        |> redirect(to: Routes.admin_shop_path(conn, :show, shop.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the shop. Please try again.")
        |> render("new.html",
          room: room,
          changeset: changeset
        )
    end
  end

  @doc """
  Renders the edit form for a given shop.
  """
  def edit(conn, %{"id" => id}) do
    shop = Shop.get(id)
    room = Room.get(shop.room_id)

    render(conn, "edit.html",
      shop: shop,
      room: room,
      changeset: Shop.edit(shop)
    )
  end

  @doc """
  Updates a shop with the given parameters.
  """
  def update(conn, %{"id" => id, "shop" => params}) do
    case Shop.update(id, params) do
      {:ok, shop} ->
        conn
        |> put_flash(:info, "#{shop.name} updated!")
        |> redirect(to: Routes.admin_shop_path(conn, :show, shop.id))

      {:error, changeset} ->
        shop = Shop.get(id)
        room = Room.get(shop.room_id)

        conn
        |> put_flash(:error, "There was an issue updating #{shop.name}. Please try again.")
        |> render("edit.html",
          shop: shop,
          room: room,
          changeset: changeset
        )
    end
  end
end
