defmodule Web.Admin.NPCEventController do
  @moduledoc """
  Admin controller for managing NPC events.
  Provides actions to list, create, edit, delete, and reload NPC script events.
  """

  use Web.AdminController

  alias Web.NPC
  alias Web.Router.Helpers, as: Routes

  @doc """
  Displays all script events for an NPC.
  """
  def index(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    render(conn, "index.html", npc: npc)
  end

  @doc """
  Renders form to create a new script event for an NPC.
  """
  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    render(conn, "new.html",
      npc: npc,
      field: ""
    )
  end

  @doc """
  Creates a new script event from a JSON string body.
  """
  def create(conn, %{"npc_id" => npc_id, "event" => %{"body" => body}}) do
    npc = NPC.get(npc_id)

    case NPC.add_event(npc, body) do
      {:ok, _npc} ->
        conn
        |> put_flash(:info, "Event created!")
        |> redirect(to: Routes.npc_event_path(conn, :index, npc.id))

      {:error, _changeset} ->
        render(conn, "new.html",
          npc: npc,
          field: body,
          error: "There was a problem updating."
        )

      {:error, :invalid, changeset} ->
        render(conn, "new.html",
          npc: npc,
          field: body,
          errors: changeset.errors
        )
    end
  end

  @doc """
  Renders the form to edit a specific event by ID.
  """
  def edit(conn, %{"npc_id" => npc_id, "id" => id}) do
    npc = NPC.get(npc_id)

    case Enum.find(npc.events, &(&1["id"] == id)) do
      nil ->
        redirect(conn, to: Routes.npc_event_path(conn, :index, npc.id))

      event ->
        render(conn, "edit.html",
          npc: npc,
          event: event,
          field: event |> Jason.encode!() |> Jason.Formatter.pretty_print()
        )
    end
  end

  @doc """
  Updates an existing event from an edited JSON string body.
  """
  def update(conn, %{"npc_id" => npc_id, "id" => id, "event" => %{"body" => body}}) do
    npc = NPC.get(npc_id)

    case Enum.find(npc.events, &(&1["id"] == id)) do
      nil ->
        redirect(conn, to: Routes.npc_event_path(conn, :index, npc.id))

      event ->
        case NPC.edit_event(npc, id, body) do
          {:ok, _npc} ->
            conn
            |> put_flash(:info, "Event updated!")
            |> redirect(to: Routes.npc_event_path(conn, :index, npc.id))

          {:error, _changeset} ->
            render(conn, "edit.html",
              npc: npc,
              event: event,
              field: body,
              error: "There was a problem updating."
            )

          {:error, :invalid, changeset} ->
            render(conn, "edit.html",
              npc: npc,
              event: event,
              field: body,
              errors: changeset.errors
            )
        end
    end
  end

  @doc """
  Deletes an NPC event by ID.
  """
  def delete(conn, %{"npc_id" => npc_id, "id" => id}) do
    npc = NPC.get(npc_id)

    case NPC.delete_event(npc, id) do
      {:ok, _npc} ->
        conn
        |> put_flash(:info, "Event removed!")
        |> redirect(to: Routes.npc_event_path(conn, :index, npc.id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem removing the event.")
        |> redirect(to: Routes.npc_event_path(conn, :index, npc.id))
    end
  end

  @doc """
  Forces save and reload of NPC events from the editor.
  """
  def reload(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    case NPC.force_save_events(npc) do
      {:ok, _npc} ->
        conn
        |> put_flash(:info, "Events reloaded!")
        |> redirect(to: Routes.npc_event_path(conn, :index, npc.id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem reloading.")
        |> redirect(to: Routes.npc_event_path(conn, :index, npc.id))
    end
  end
end
