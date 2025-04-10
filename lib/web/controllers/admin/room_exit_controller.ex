defmodule Web.Admin.RoomExitController do
  @moduledoc """
  Admin controller for managing room exits.
  """

  use Web.AdminController

  alias Web.Router.Helpers, as: Routes
  alias Web.Proficiency
  alias Web.Room
  alias Web.Zone

  @doc """
  Renders form to create a new exit from a room.
  """
  def new(conn, %{"room_id" => room_id, "direction" => direction}) do
    room = Room.get(room_id)
    zone = Zone.get(room.zone_id)

    render(conn, "new.html",
      changeset: Room.new_exit(),
      zone: zone,
      room: room,
      direction: direction,
      proficiencies: Proficiency.all()
    )
  end

  @doc """
  Handles creation of a room exit.
  """
  def create(conn, %{"room_id" => room_id, "exit" => params, "direction" => direction}) do
    case Room.create_exit(params) do
      {:ok, _room_exit} ->
        conn
        |> put_flash(:info, "Exit created!")
        |> redirect(to: Routes.admin_room_path(conn, :show, room_id))

      {:error, changeset} ->
        room = Room.get(room_id)
        zone = Zone.get(room.zone_id)

        render(conn, "new.html",
          changeset: changeset,
          zone: zone,
          room: room,
          direction: direction,
          proficiencies: Proficiency.all()
        )
    end
  end

  @doc """
  Deletes an existing room exit.
  """
  def delete(conn, %{"id" => id, "room_id" => room_id}) do
    case Room.delete_exit(id) do
      {:ok, _room_exit} ->
        conn
        |> put_flash(:info, "Exit removed!")
        |> redirect(to: Routes.admin_room_path(conn, :show, room_id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was an issue removing the exit. Please try again.")
        |> redirect(to: Routes.admin_room_path(conn, :show, room_id))
    end
  end
end
