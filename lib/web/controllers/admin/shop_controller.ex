defmodule Web.Admin.ShopController do
  @moduledoc """
  Admin controller for managing in-game shops associated with rooms.
  """

  use Web.AdminController

  alias Web.Room
  alias Web.Shop

  @doc """
  Displays a single shop along with its associated room.
  """
  def show(conn, %{"id" => id}) do
    shop = Shop.get(id)
    room = Room.get(shop.room_id)

    render(conn, :show,
      shop: shop,
      room: room
    )
  end

  @doc """
  Renders the new shop form for a given room.
  """
  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)

    render(conn, :new,
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
        redirect(conn,
          to: ~p"/admin/shops/#{shop.id}",
          flash: [info: "#{shop.name} created!"]
        )

      {:error, changeset} ->
        render(conn, :new,
          room: room,
          changeset: changeset,
          error_flash: "There was an issue creating the shop. Please try again."
        )
    end
  end

  @doc """
  Renders the edit form for a given shop.
  """
  def edit(conn, %{"id" => id}) do
    shop = Shop.get(id)
    room = Room.get(shop.room_id)

    render(conn, :edit,
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
        redirect(conn,
          to: ~p"/admin/shops/#{shop.id}",
          flash: [info: "#{shop.name} updated!"]
        )

      {:error, changeset} ->
        shop = Shop.get(id)
        room = Room.get(shop.room_id)

        render(conn, :edit,
          shop: shop,
          room: room,
          changeset: changeset,
          error_flash: "There was an issue updating #{shop.name}. Please try again."
        )
    end
  end
end
