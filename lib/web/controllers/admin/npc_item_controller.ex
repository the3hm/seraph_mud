defmodule Web.Admin.NPCItemController do
  @moduledoc """
  Admin controller for managing items associated with NPCs.
  Provides actions to add, edit, update, and delete NPC-held items.
  """

  use Web.AdminController

  alias Web.NPC
  alias Web.Item
  alias Web.Router.Helpers, as: Routes

  @doc """
  Renders form for creating a new item for the given NPC.
  """
  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    changeset = NPC.new_item(npc)

    render(conn, "new.html",
      npc: npc,
      changeset: changeset,
      items: Item.all()
    )
  end

  @doc """
  Creates a new item entry associated with the given NPC.
  """
  def create(conn, %{"npc_id" => npc_id, "npc_item" => params}) do
    npc = NPC.get(npc_id)

    case NPC.add_item(npc, params) do
      {:ok, npc_item} ->
        conn
        |> put_flash(:info, "Item added!")
        |> redirect(to: Routes.npc_path(conn, :show, npc_item.npc_id))

      {:error, changeset} ->
        render(conn, "new.html",
          npc: npc,
          changeset: changeset,
          items: Item.all()
        )
    end
  end

  @doc """
  Renders the form to edit an existing NPC item.
  """
  def edit(conn, %{"id" => id}) do
    npc_item = NPC.get_item(id)
    npc = NPC.get(npc_item.npc_id)
    changeset = NPC.edit_item(npc_item)

    render(conn, "edit.html",
      npc_item: npc_item,
      npc: npc,
      changeset: changeset,
      items: Item.all()
    )
  end

  @doc """
  Updates an existing item associated with the NPC.
  """
  def update(conn, %{"id" => id, "npc_item" => params}) do
    case NPC.update_item(id, params) do
      {:ok, npc_item} ->
        conn
        |> put_flash(:info, "Item updated!")
        |> redirect(to: Routes.npc_path(conn, :show, npc_item.npc_id))

      {:error, changeset} ->
        npc_item = NPC.get_item(id)
        npc = NPC.get(npc_item.npc_id)

        render(conn, "edit.html",
          npc_item: npc_item,
          npc: npc,
          changeset: changeset,
          items: Item.all()
        )
    end
  end

  @doc """
  Deletes an item held by the NPC.
  """
  def delete(conn, %{"id" => id}) do
    case NPC.delete_item(id) do
      {:ok, npc_item} ->
        conn
        |> put_flash(:info, "Item removed!")
        |> redirect(to: Routes.npc_path(conn, :show, npc_item.npc_id))

      _ ->
        npc_item = NPC.get_item(id)

        conn
        |> put_flash(:error, "There was an issue deleting the item from the NPC. Please try again.")
        |> redirect(to: Routes.npc_path(conn, :show, npc_item.npc_id))
    end
  end
end
