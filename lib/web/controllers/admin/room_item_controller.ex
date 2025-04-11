defmodule Web.Admin.RoomItemController do
  @moduledoc """
  Admin controller for managing items placed or spawned in rooms.
  """

  use Web.AdminController

  alias Web.Item
  alias Web.Room

  @doc """
  Renders form for adding an existing item to a room (non-spawn).
  """
  def new(conn, %{"room_id" => room_id, "spawn" => "false"}) do
    room = Room.get(room_id)

    render(conn, "add-item.html",
      items: Item.all(),
      room: room
    )
  end

  @doc """
  Renders form for creating a new item spawn in a room.
  """
  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)

    render(conn, "new.html",
      items: Item.all(),
      room: room,
      changeset: Room.new_item(room)
    )
  end

  @doc """
  Adds an existing item instance to a room.
  """
  def create(conn, %{"room_id" => room_id, "item" => %{"id" => item_id}}) do
    room = Room.get(room_id)

    case Room.add_item(room, item_id) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "Item added to #{room.name}")
        |> redirect(to: ~p"/admin/rooms/#{room.id}")

      {:error, _changeset} ->
        conn
        |> put_flash(
          :error,
          "There was an issue adding the item to #{room.name}. Please try again."
        )
        |> render("add-item.html",
          items: Item.all(),
          room: room
        )
    end
  end

  @doc """
  Creates a new item spawn definition in a room.
  """
  def create(conn, %{"room_id" => room_id, "room_item" => params}) do
    room = Room.get(room_id)

    case Room.create_item(room, params) do
      {:ok, room_item} ->
        conn
        |> put_flash(:info, "Item spawn added to the room!")
        |> redirect(to: ~p"/admin/rooms/#{room_item.room_id}")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue adding the item spawn. Please try again.")
        |> render("new.html",
          items: Item.all(),
          room: room,
          changeset: changeset
        )
    end
  end

  @doc """
  Deletes a room item spawn from a room.
  """
  def delete(conn, %{"id" => id}) do
    case Room.delete_item(id) do
      {:ok, room_item} ->
        conn
        |> put_flash(:info, "Item spawn deleted!")
        |> redirect(to: ~p"/admin/rooms/#{room_item.room_id}")

      _ ->
        conn
        |> put_flash(:error, "There was an issue deleting the item spawn. Please try again.")
        |> redirect(to: ~p"/admin/dashboard")
    end
  end
end
