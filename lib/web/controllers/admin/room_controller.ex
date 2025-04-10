defmodule Web.Admin.RoomController do
  @moduledoc """
  Admin controller for creating, viewing, and managing rooms inside a zone.
  """

  use Web.AdminController

  alias Web.Router.Helpers, as: Routes
  alias Web.Room
  alias Web.Zone

  @doc """
  Displays details for a specific room.
  """
  def show(conn, %{"id" => id}) do
    room = Room.get(id)

    render(conn, "show.html",
      room: room
    )
  end

  @doc """
  Renders the form for creating a new room in a zone.
  """
  def new(conn, %{"zone_id" => zone_id} = params) do
    zone = Zone.get(zone_id)

    render(conn, "new.html",
      zone: zone,
      changeset: Room.new(zone, params)
    )
  end

  @doc """
  Creates a new room in the specified zone.
  """
  def create(conn, %{"zone_id" => zone_id, "room" => params}) do
    zone = Zone.get(zone_id)

    case Room.create(zone, params) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "#{room.name} created!")
        |> redirect(to: Routes.admin_room_path(conn, :show, room.id))

      {:error, changeset} ->
        render(conn, "new.html",
          zone: zone,
          changeset: changeset
        )
    end
  end

  @doc """
  Renders the edit form for an existing room.
  """
  def edit(conn, %{"id" => id}) do
    room = Room.get(id)

    render(conn, "edit.html",
      room: room,
      changeset: Room.edit(room)
    )
  end

  @doc """
  Updates a room with new parameters.
  """
  def update(conn, %{"id" => id, "room" => params}) do
    case Room.update(id, params) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "#{room.name} updated!")
        |> redirect(to: Routes.admin_room_path(conn, :show, room.id))

      {:error, changeset} ->
        room = Room.get(id)

        render(conn, "edit.html",
          room: room,
          changeset: changeset
        )
    end
  end

  @doc """
  Deletes a room, unless it is a graveyard or the starting room.
  """
  def delete(conn, %{"id" => id}) do
    case Room.delete(id) do
      {:ok, room} ->
        conn
        |> put_flash(:info, "#{room.name} has been deleted!")
        |> redirect(to: Routes.admin_zone_path(conn, :show, room.zone_id))

      {:error, :graveyard, room} ->
        conn
        |> put_flash(:error, "#{room.name} is marked as a graveyard and cannot be deleted.")
        |> redirect(to: Routes.admin_room_path(conn, :show, room.id))

      {:error, :starting_room, room} ->
        conn
        |> put_flash(:error, "#{room.name} is the starting room and cannot be deleted.")
        |> redirect(to: Routes.admin_room_path(conn, :show, room.id))
    end
  end
end
