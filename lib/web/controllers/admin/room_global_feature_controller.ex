defmodule Web.Admin.RoomGlobalFeatureController do
  @moduledoc """
  Admin controller for managing global features associated with rooms.
  """

  use Web.AdminController

  alias Web.Feature
  alias Web.Room

  @doc """
  Renders form to add a global feature to a room.
  """
  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)

    render(conn, :new,
      room: room,
      features: Feature.all()
    )
  end

  @doc """
  Adds a global feature to a room.
  """
  def create(conn, %{"room_id" => room_id, "room" => %{"feature_id" => feature_id}}) do
    room = Room.get(room_id)

    case Room.add_global_feature(room, feature_id) do
      {:ok, _room} ->
        redirect(conn,
          to: ~p"/admin/rooms/#{room.id}",
          flash: [info: "Room feature added!"]
        )

      :error ->
        redirect(conn,
          to: ~p"/admin/rooms/#{room.id}/features/new",
          flash: [error: "There was an issue adding the feature. Please try again."]
        )
    end
  end

  @doc """
  Removes a global feature from a room.
  """
  def delete(conn, %{"room_id" => room_id, "id" => feature_id}) do
    room = Room.get(room_id)

    case Room.remove_global_feature(room, feature_id) do
      {:ok, _room} ->
        redirect(conn,
          to: ~p"/admin/rooms/#{room.id}",
          flash: [info: "Room feature removed!"]
        )

      :error ->
        redirect(conn,
          to: ~p"/admin/rooms/#{room.id}/features/new",
          flash: [error: "There was an issue removing the feature. Please try again."]
        )
    end
  end
end
