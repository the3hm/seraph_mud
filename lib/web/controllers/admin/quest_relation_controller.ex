defmodule Web.Admin.QuestRelationController do
  @moduledoc """
  Admin controller for managing quest chains (relations between quests).
  """

  use Web.AdminController

  alias Web.Quest
  alias Web.Router.Helpers, as: Routes

  @doc """
  Renders a form to create a new quest relation (parent/child).
  """
  def new(conn, %{"quest_id" => quest_id, "side" => side}) do
    quest = Quest.get(quest_id)

    render(conn, "new.html",
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
        conn
        |> put_flash(:info, "Quest chain updated for #{quest.name}.")
        |> redirect(to: Routes.admin_quest_path(conn, :show, quest.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem adding to the quest chain. Please try again.")
        |> render("new.html",
          quest: quest,
          side: side,
          changeset: changeset
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
        conn
        |> put_flash(:info, "Quest chain updated for #{quest.name}.")
        |> redirect(to: Routes.admin_quest_path(conn, :show, quest.id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem updating the quest chain. Please try again.")
        |> redirect(to: Routes.admin_quest_path(conn, :show, quest.id))
    end
  end
end
