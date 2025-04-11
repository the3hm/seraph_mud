defmodule Web.Admin.NPCController do
  @moduledoc """
  Admin controller for managing NPCs.
  Includes actions to list, view, create, clone, edit, and update NPCs.
  """

  use Web.AdminController

  alias Web.NPC
  alias Web.Router.Helpers, as: Routes

  plug(Web.Plug.FetchPage when action in [:index])

  @doc """
  List all NPCs with optional filter params.
  """
  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "npc", %{})
    %{page: npcs, pagination: pagination} = NPC.all(filter: filter, page: page, per: per)

    render(conn, "index.html",
      npcs: npcs,
      filter: filter,
      pagination: pagination
    )
  end

  @doc """
  Display details for a single NPC.
  """
  def show(conn, %{"id" => id}) do
    npc = NPC.get(id)

    render(conn, "show.html", npc: npc)
  end

  @doc """
  Render the new NPC form, optionally cloned from an existing NPC.
  """
  def new(conn, %{"clone_id" => clone_id}) do
    changeset = NPC.clone(clone_id)

    render(conn, "new.html", changeset: changeset)
  end

  def new(conn, _params) do
    changeset = NPC.new()

    render(conn, "new.html", changeset: changeset)
  end

  @doc """
  Create a new NPC from parameters.
  """
  def create(conn, %{"npc" => params}) do
    case NPC.create(params) do
      {:ok, npc} ->
        conn
        |> put_flash(:info, "Created #{npc.name}!")
        |> redirect(to: Routes.npc_path(conn, :show, npc.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the NPC. Please try again.")
        |> render("new.html", changeset: changeset)
    end
  end

  @doc """
  Render the form to edit an existing NPC.
  """
  def edit(conn, %{"id" => id}) do
    npc = NPC.get(id)
    changeset = NPC.edit(npc)

    render(conn, "edit.html",
      npc: npc,
      changeset: changeset
    )
  end

  @doc """
  Update an existing NPC with new parameters.
  """
  def update(conn, %{"id" => id, "npc" => params}) do
    case NPC.update(id, params) do
      {:ok, npc} ->
        conn
        |> put_flash(:info, "Updated #{npc.name}!")
        |> redirect(to: Routes.npc_path(conn, :show, npc.id))

      {:error, changeset} ->
        npc = NPC.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{npc.name}. Please try again.")
        |> render("edit.html",
          npc: npc,
          changeset: changeset
        )
    end
  end
end
