defmodule Web.Admin.RoomFeatureController do
  @moduledoc """
  Admin controller for managing room-specific features (custom room content blocks).
  """

  use Web.AdminController

  alias Web.Router.Helpers, as: Routes
  alias Web.Room

  @doc """
  Renders the form to add a new feature to a room.
  """
  def new(conn, %{"room_id" => room_id}) do
    room = Room.get(room_id)

    render(conn, "new.html",
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
        conn
        |> put_flash(:info, "Feature added!")
        |> redirect(to: Routes.admin_room_path(conn, :show, room.id))

      {:error, feature} ->
        conn
        |> put_flash(:error, "There was an issue adding the feature. Please try again.")
        |> render("new.html",
          room: room,
          feature: feature
        )
    end
  end

  @doc """
  Renders the edit form for a specific feature.
  """
  def edit(conn, %{"room_id" => room_id, "id" => id}) do
    room = Room.get(room_id)
    feature = Room.get_feature(room, id)

    render(conn, "edit.html",
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
        conn
        |> put_flash(:info, "Room feature updated!")
        |> redirect(to: Routes.admin_room_path(conn, :show, room.id))

      {:error, feature} ->
        conn
        |> put_flash(:error, "There was an issue updating the feature. Please try again.")
        |> render("edit.html",
          room: room,
          feature: feature
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
        conn
        |> put_flash(:info, "Feature removed!")
        |> redirect(to: Routes.admin_room_path(conn, :show, room.id))

      _ ->
        conn
        |> put_flash(:error, "There was an issue removing the feature. Please try again.")
        |> redirect(to: Routes.dashboard_path(conn, :index))
    end
  end
end
