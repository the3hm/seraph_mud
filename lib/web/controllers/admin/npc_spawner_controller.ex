defmodule Web.Admin.NPCSpawnerController do
  @moduledoc """
  Admin controller for managing NPC spawners within zones.
  """

  use Web.AdminController

  alias Web.NPC
  alias Web.Zone
  alias Web.Router.Helpers, as: Routes

  @doc """
  Show a specific NPC spawner.
  """
  def show(conn, %{"id" => id}) do
    npc_spawner = NPC.get_spawner(id)
    npc = NPC.get(npc_spawner.npc_id)

    render(conn, "show.html", npc_spawner: npc_spawner, npc: npc)
  end

  @doc """
  Render the form for creating a new spawner with a preselected zone.
  """
  def new(conn, %{"npc_id" => npc_id, "npc_spawner" => %{"zone_id" => zone_id}}) do
    zone = Zone.get(zone_id)
    npc = NPC.get(npc_id)

    render(conn, "new.html",
      npc: npc,
      zone: zone,
      changeset: NPC.new_spawner(npc)
    )
  end

  @doc """
  Render the form for creating a new spawner without a zone selected.
  """
  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    render(conn, "new.html",
      npc: npc,
      changeset: NPC.new_spawner(npc)
    )
  end

  @doc """
  Create a new NPC spawner for a given NPC.
  """
  def create(conn, %{"npc_id" => npc_id, "npc_spawner" => params}) do
    npc = NPC.get(npc_id)

    case NPC.add_spawner(npc, params) do
      {:ok, npc_spawner} ->
        conn
        |> put_flash(:info, "Spawner created!")
        |> redirect(to: Routes.admin_npc_path(conn, :show, npc_spawner.npc_id))

      {:error, changeset} ->
        conn
        |> assign(:npc, npc)
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  @doc """
  Edit an existing NPC spawner.
  """
  def edit(conn, %{"id" => id}) do
    npc_spawner = NPC.get_spawner(id)

    render(conn, "edit.html",
      npc_spawner: npc_spawner,
      changeset: NPC.edit_spawner(npc_spawner)
    )
  end

  @doc """
  Update an existing NPC spawner.
  """
  def update(conn, %{"id" => id, "npc_spawner" => params}) do
    case NPC.update_spawner(id, params) do
      {:ok, npc_spawner} ->
        conn
        |> put_flash(:info, "Spawner updated!")
        |> redirect(to: Routes.admin_npc_path(conn, :show, npc_spawner.npc_id))

      {:error, changeset} ->
        npc_spawner = NPC.get_spawner(id)

        conn
        |> put_flash(:error, "There was an issue updating the spawner. Please try again.")
        |> assign(:npc_spawner, npc_spawner)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  @doc """
  Delete an NPC spawner.
  """
  def delete(conn, %{"id" => id, "npc_id" => npc_id}) do
    case NPC.delete_spawner(id) do
      {:ok, _spawner} ->
        conn
        |> put_flash(:info, "NPC spawner deleted!")
        |> redirect(to: Routes.admin_npc_path(conn, :show, npc_id))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "There was an issue deleting the spawner. Please try again.")
        |> redirect(to: Routes.admin_npc_path(conn, :show, npc_id))
    end
  end
end
