defmodule Web.Admin.QuestRelationController do
  @moduledoc """
  Admin controller for managing quest chains (relations between quests).
  """

  use Web.AdminController

  alias Web.Quest

  @doc """
  Renders a form to create a new quest relation (parent/child).
  """
  def new(conn, %{"quest_id" => quest_id, "side" => side}) do
    quest = Quest.get(quest_id)

    render(conn, :new,
      quest: quest,
      side: side,
      changeset: Quest.new_relation()
    )
  end

  @doc """
  Creates a quest relation on the specified side (:parent or :child).
  """
  def create(conn, %{"quest_id" => quest_id, "side" => side, "quest_relation" => params}) do
    quest = Quest.get(quest_id)

    case Quest.create_relation(quest, side, params) do
      {:ok, _relation} ->
        redirect(conn,
          to: ~p"/admin/quests/#{quest.id}",
          flash: [info: "Quest chain updated for #{quest.name}."]
        )

      {:error, changeset} ->
        render(conn, :new,
          quest: quest,
          side: side,
          changeset: changeset,
          error_flash: "There was a problem adding to the quest chain. Please try again."
        )
    end
  end

  @doc """
  Deletes a quest relation.
  """
  def delete(conn, %{"id" => id, "quest_id" => quest_id}) do
    quest = Quest.get(quest_id)

    case Quest.delete_relation(id) do
      {:ok, _relation} ->
        redirect(conn,
          to: ~p"/admin/quests/#{quest.id}",
          flash: [info: "Quest chain updated for #{quest.name}."]
        )

      {:error, _changeset} ->
        redirect(conn,
          to: ~p"/admin/quests/#{quest.id}",
          flash: [error: "There was a problem updating the quest chain. Please try again."]
        )
    end
  end
end
