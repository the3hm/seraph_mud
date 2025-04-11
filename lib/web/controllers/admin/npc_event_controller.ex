defmodule Web.Admin.NPCEventController do
  @moduledoc """
  Admin controller for managing NPC events.
  Provides actions to list, create, edit, delete, and reload NPC script events.
  """

  use Web.AdminController

  alias Web.NPC

  @doc """
  Displays all script events for an NPC.
  """
  def index(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    render(conn, :index, npc: npc)
  end

  @doc """
  Renders form to create a new script event for an NPC.
  """
  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)
    render(conn, :new, npc: npc, field: "")
  end

  @doc """
  Creates a new script event from a JSON string body.
  """
  def create(conn, %{"npc_id" => npc_id, "event" => %{"body" => body}}) do
    npc = NPC.get(npc_id)

    case NPC.add_event(npc, body) do
      {:ok, _npc} ->
        redirect(conn,
          to: ~p"/admin/npcs/#{npc.id}/events",
          flash: [info: "Event created!"]
        )

      {:error, _changeset} ->
        render(conn, :new,
          npc: npc,
          field: body,
          error_flash: "There was a problem updating."
        )

      {:error, :invalid, changeset} ->
        render(conn, :new,
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
        redirect(conn, to: ~p"/admin/npcs/#{npc.id}/events")

      event ->
        render(conn, :edit,
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
        redirect(conn, to: ~p"/admin/npcs/#{npc.id}/events")

      event ->
        case NPC.edit_event(npc, id, body) do
          {:ok, _npc} ->
            redirect(conn,
              to: ~p"/admin/npcs/#{npc.id}/events",
              flash: [info: "Event updated!"]
            )

          {:error, _changeset} ->
            render(conn, :edit,
              npc: npc,
              event: event,
              field: body,
              error_flash: "There was a problem updating."
            )

          {:error, :invalid, changeset} ->
            render(conn, :edit,
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
        redirect(conn,
          to: ~p"/admin/npcs/#{npc.id}/events",
          flash: [info: "Event removed!"]
        )

      {:error, _changeset} ->
        redirect(conn,
          to: ~p"/admin/npcs/#{npc.id}/events",
          flash: [error: "There was a problem removing the event."]
        )
    end
  end

  @doc """
  Forces save and reload of NPC events from the editor.
  """
  def reload(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    case NPC.force_save_events(npc) do
      {:ok, _npc} ->
        redirect(conn,
          to: ~p"/admin/npcs/#{npc.id}/events",
          flash: [info: "Events reloaded!"]
        )

      {:error, _changeset} ->
        redirect(conn,
          to: ~p"/admin/npcs/#{npc.id}/events",
          flash: [error: "There was a problem reloading."]
        )
    end
  end
end
