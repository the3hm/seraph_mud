defmodule Web.Admin.RoomFeatureController do
  @moduledoc """
  Admin controller for managing room-specific features (custom room content blocks).
  """

  use Web.AdminController

  alias Web.Room

  @doc """
  Renders the form to add a new feature to a room.
  """
  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)

    render(conn, :new,
      room: room,
      feature: %{}
    )
  end

  @doc """
  Adds a feature to a room.
  """
  def create(conn, %{"room_id" => room_id, "feature" => params}) do
    room = Room.get(room_id)

    case Room.add_feature(room, params) do
      {:ok, _room} ->
        redirect(conn,
          to: ~p"/admin/rooms/#{room.id}",
          flash: [info: "Feature added!"]
        )

      {:error, feature} ->
        render(conn, :new,
          room: room,
          feature: feature,
          error_flash: "There was an issue adding the feature. Please try again."
        )
    end
  end

  @doc """
  Renders the edit form for a specific feature.
  """
  def edit(conn, %{"room_id" => room_id, "id" => id}) do
    room = Room.get(room_id)
    feature = Room.get_feature(room, id)

    render(conn, :edit,
      room: room,
      feature: feature
    )
  end

  @doc """
  Updates a feature in a room.
  """
  def update(conn, %{"room_id" => room_id, "id" => id, "feature" => params}) do
    room = Room.get(room_id)

    case Room.edit_feature(room, id, params) do
      {:ok, _room} ->
        redirect(conn,
          to: ~p"/admin/rooms/#{room.id}",
          flash: [info: "Room feature updated!"]
        )

      {:error, feature} ->
        render(conn, :edit,
          room: room,
          feature: feature,
          error_flash: "There was an issue updating the feature. Please try again."
        )
    end
  end

  @doc """
  Removes a feature from a room.
  """
  def delete(conn, %{"room_id" => room_id, "id" => id}) do
    room = Room.get(room_id)

    case Room.delete_feature(room, id) do
      {:ok, _} ->
        redirect(conn,
          to: ~p"/admin/rooms/#{room.id}",
          flash: [info: "Feature removed!"]
        )

      _ ->
        redirect(conn,
          to: ~p"/admin/dashboard",
          flash: [error: "There was an issue removing the feature. Please try again."]
        )
    end
  end
end
