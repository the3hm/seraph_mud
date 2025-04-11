defmodule Web.Admin.NPCSpawnerController do
  @moduledoc """
  Admin controller for managing NPC spawners within zones.
  """

  use Web.AdminController

  alias Web.NPC
  alias Web.Zone

  @doc """
  Show a specific NPC spawner.
  """
  def show(conn, %{"id" => id}) do
    npc_spawner = NPC.get_spawner(id)
    npc = NPC.get(npc_spawner.npc_id)

    render(conn, :show, npc_spawner: npc_spawner, npc: npc)
  end

  @doc """
  Render the form for creating a new spawner with a preselected zone.
  """
  def new(conn, %{"npc_id" => npc_id, "npc_spawner" => %{"zone_id" => zone_id}}) do
    zone = Zone.get(zone_id)
    npc = NPC.get(npc_id)

    render(conn, :new,
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

    render(conn, :new,
      npc: npc,
      changeset: NPC.new_spawner(npc)
    )
  end

  @doc """
  Create a new NPC spawner for a given NPC.
  """
  def create(conn, %{"npc_id" => npc_id, "npc_spawner" => params}) do
    npc = NPC.get(npc_id)

    with {:ok, npc_spawner} <- NPC.add_spawner(npc, params) do
      redirect(conn,
        to: ~p"/admin/npcs/#{npc_spawner.npc_id}",
        flash: [info: "Spawner created!"]
      )
    else
      {:error, changeset} ->
        render(conn, :new,
          npc: npc,
          changeset: changeset
        )
    end
  end

  @doc """
  Edit an existing NPC spawner.
  """
  def edit(conn, %{"id" => id}) do
    npc_spawner = NPC.get_spawner(id)

    render(conn, :edit,
      npc_spawner: npc_spawner,
      changeset: NPC.edit_spawner(npc_spawner)
    )
  end

  @doc """
  Update an existing NPC spawner.
  """
  def update(conn, %{"id" => id, "npc_spawner" => params}) do
    with {:ok, npc_spawner} <- NPC.update_spawner(id, params) do
      redirect(conn,
        to: ~p"/admin/npcs/#{npc_spawner.npc_id}",
        flash: [info: "Spawner updated!"]
      )
    else
      {:error, changeset} ->
        npc_spawner = NPC.get_spawner(id)

        render(conn, :edit,
          npc_spawner: npc_spawner,
          changeset: changeset,
          error_flash: "There was an issue updating the spawner. Please try again."
        )
    end
  end

  @doc """
  Delete an NPC spawner.
  """
  def delete(conn, %{"id" => id, "npc_id" => npc_id}) do
    with {:ok, _spawner} <- NPC.delete_spawner(id) do
      redirect(conn,
        to: ~p"/admin/npcs/#{npc_id}",
        flash: [info: "NPC spawner deleted!"]
      )
    else
      {:error, _reason} ->
        redirect(conn,
          to: ~p"/admin/npcs/#{npc_id}",
          flash: [error: "There was an issue deleting the spawner. Please try again."]
        )
    end
  end
end
