defmodule Web.Admin.ZoneController do
  @moduledoc """
  Admin controller for managing game zones.
  Allows viewing, creating, and editing zones.
  """

  use Web.AdminController

  alias Web.Router.Helpers, as: Routes
  alias Web.Zone

  plug Web.Plug.FetchPage when action in [:index]

  @doc """
  Lists all zones with pagination.
  """
  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: zones, pagination: pagination} = Zone.all(page: page, per: per)

    render(conn, "index.html",
      zones: zones,
      pagination: pagination
    )
  end

  @doc """
  Shows details for a specific zone.
  """
  def show(conn, %{"id" => id}) do
    render(conn, "show.html", zone: Zone.get(id))
  end

  @doc """
  Renders the new zone creation form.
  """
  def new(conn, _params) do
    render(conn, "new.html", changeset: Zone.new())
  end

  @doc """
  Creates a new zone and redirects to its show page.
  """
  def create(conn, %{"zone" => params}) do
    case Zone.create(params) do
      {:ok, zone} ->
        conn
        |> put_flash(:info, "#{zone.name} created!")
        |> redirect(to: Routes.admin_zone_path(conn, :show, zone.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the zone. Please try again.")
        |> render("new.html", changeset: changeset)
    end
  end

  @doc """
  Renders the edit form for a zone.
  """
  def edit(conn, %{"id" => id}) do
    zone = Zone.get(id)

    render(conn, "edit.html",
      zone: zone,
      changeset: Zone.edit(zone)
    )
  end

  @doc """
  Updates a zone with new attributes.
  """
  def update(conn, %{"id" => id, "zone" => params}) do
    case Zone.update(id, params) do
      {:ok, zone} ->
        conn
        |> put_flash(:info, "#{zone.name} updated!")
        |> redirect(to: Routes.admin_zone_path(conn, :show, zone.id))

      {:error, changeset} ->
        zone = Zone.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{zone.name}. Please try again.")
        |> render("edit.html",
          zone: zone,
          changeset: changeset
        )
    end
  end
end
