defmodule Web.Admin.RoomExitController do
  @moduledoc """
  Admin controller for managing room exits.
  """

  use Web.AdminController

  alias Web.Proficiency
  alias Web.Room
  alias Web.Zone

  @doc """
  Renders form to create a new exit from a room.
  """
  def new(conn, %{"room_id" => room_id, "direction" => direction}) do
    room = Room.get(room_id)
    zone = Zone.get(room.zone_id)

    render(conn, :new,
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
        redirect(conn,
          to: ~p"/admin/rooms/#{room_id}",
          flash: [info: "Exit created!"]
        )

      {:error, changeset} ->
        room = Room.get(room_id)
        zone = Zone.get(room.zone_id)

        render(conn, :new,
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
        redirect(conn,
          to: ~p"/admin/rooms/#{room_id}",
          flash: [info: "Exit removed!"]
        )

      {:error, _changeset} ->
        redirect(conn,
          to: ~p"/admin/rooms/#{room_id}",
          flash: [error: "There was an issue removing the exit. Please try again."]
        )
    end
  end
end
