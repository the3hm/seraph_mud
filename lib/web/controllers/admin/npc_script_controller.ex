defmodule Web.Admin.NPCScriptController do
  @moduledoc """
  Admin controller for managing NPC scripts.
  Allows viewing and editing of NPC scripts.
  """

  use Web.AdminController

  alias Web.NPC
  alias Web.Router.Helpers, as: Routes

  @doc """
  Shows the script associated with the given NPC.
  """
  def show(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    render(conn, "show.html", npc: npc)
  end

  @doc """
  Renders the form to edit the script of the given NPC.
  """
  def edit(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    changeset = NPC.edit(npc)

    render(conn, "edit.html", npc: npc, changeset: changeset)
  end

  @doc """
  Updates the script of the NPC.
  """
  def update(conn, %{"npc_id" => id, "npc" => params}) do
    case NPC.update(id, params) do
      {:ok, npc} ->
        conn
        |> put_flash(:info, "Updated #{npc.name}!")
        |> redirect(to: Routes.admin_npc_script_path(conn, :show, npc.id))

      {:error, changeset} ->
        npc = NPC.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{npc.name}. Please try again.")
        |> assign(:npc, npc)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
