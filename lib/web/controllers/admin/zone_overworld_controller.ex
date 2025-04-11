defmodule Web.Admin.ZoneOverworldController do
  @moduledoc """
  Admin controller for managing overworld zones, including exits and maps.
  """

  use Web.AdminController

  alias Web.ErrorView
  alias Web.Zone

  @doc """
  Renders the exits view if the zone supports overworld.
  """
  def exits(conn, %{"id" => id}) do
    zone = Zone.get(id)

    if Zone.overworld?(zone) do
      render(conn, :exits, zone: zone)
    else
      redirect(conn,
        to: ~p"/admin/zones/#{zone.id}",
        flash: [error: "This zone does not have an overworld"]
      )
    end
  end

  @doc """
  Updates the overworld map of a zone.
  """
  def update(conn, %{"id" => id, "zone" => params}) do
    case Zone.update_map(id, params) do
      {:ok, zone} ->
        redirect(conn,
          to: ~p"/admin/zones/#{zone.id}",
          flash: [info: "#{zone.name} updated!"]
        )

      {:error, _changeset} ->
        zone = Zone.get(id)

        redirect(conn,
          to: ~p"/admin/zones/#{zone.id}",
          flash: [error: "There was an issue updating #{zone.name}'s map. Please try again."]
        )
    end
  end

  @doc """
  Creates a new overworld exit for a zone.
  """
  def create_exit(conn, %{"id" => id, "exit" => params}) do
    zone = Zone.get(id)

    case Zone.add_overworld_exit(zone, params) do
      {:ok, _zone, room_exit} ->
        conn
        |> put_status(:created)
        |> render(:exit, room_exit: room_exit)

      :error ->
        conn
        |> put_status(:bad_request)
        |> render(ErrorView, :error)
    end
  end

  @doc """
  Deletes an existing overworld exit from a zone.
  """
  def delete_exit(conn, %{"id" => id, "exit_id" => exit_id}) do
    zone = Zone.get(id)

    case Zone.delete_overworld_exit(zone, exit_id) do
      {:ok, _zone} ->
        send_resp(conn, :no_content, "")
    end
  end
end
