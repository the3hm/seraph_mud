defmodule Web.Admin.NPCScriptController do
  @moduledoc """
  Admin controller for managing NPC scripts.
  Allows viewing and editing of NPC scripts.
  """

  use Web.AdminController

  alias Web.NPC

  @doc """
  Shows the script associated with the given NPC.
  """
  def show(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    render(conn, :show, npc: npc)
  end

  @doc """
  Renders the form to edit the script of the given NPC.
  """
  def edit(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    render(conn, :edit, npc: npc, changeset: NPC.edit(npc))
  end

  @doc """
  Updates the script of the NPC.
  """
  def update(conn, %{"npc_id" => id, "npc" => params}) do
    case NPC.update(id, params) do
      {:ok, npc} ->
        redirect(conn,
          to: ~p"/admin/npcs/#{npc.id}/script",
          flash: [info: "Updated #{npc.name}!"]
        )

      {:error, changeset} ->
        npc = NPC.get(id)

        render(conn, :edit,
          npc: npc,
          changeset: changeset,
          error_flash: "There was an issue updating #{npc.name}. Please try again."
        )
    end
  end
end
