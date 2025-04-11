defmodule Web.Admin.QuestStepController do
  @moduledoc """
  Admin controller for managing individual quest steps.
  """

  use Web.AdminController

  alias Web.Quest

  @doc """
  Renders the new quest step form.
  """
  def new(conn, %{"quest_id" => quest_id, "quest_step" => %{"type" => type}}) do
    quest = Quest.get(quest_id)
    changeset = Quest.new_step(quest)

    render(conn, :new,
      quest: quest,
      type: type,
      changeset: changeset
    )
  end

  @doc """
  Redirects to new form with nil type if not provided.
  """
  def new(conn, %{"quest_id" => quest_id}) do
    new(conn, %{"quest_id" => quest_id, "quest_step" => %{"type" => nil}})
  end

  @doc """
  Creates a new step for a given quest.
  """
  def create(conn, %{"quest_id" => quest_id, "quest_step" => params}) do
    quest = Quest.get(quest_id)

    case Quest.create_step(quest, params) do
      {:ok, _step} ->
        redirect(conn,
          to: ~p"/admin/quests/#{quest.id}",
          flash: [info: "Step added for #{quest.name}."]
        )

      {:error, changeset} ->
        render(conn, :new,
          quest: quest,
          type: params["type"],
          changeset: changeset
        )
    end
  end

  @doc """
  Renders the edit form for a quest step.
  """
  def edit(conn, %{"id" => id}) do
    step = Quest.get_step(id)

    render(conn, :edit,
      step: step,
      quest: step.quest,
      changeset: Quest.edit_step(step)
    )
  end

  @doc """
  Updates a quest step's details.
  """
  def update(conn, %{"id" => id, "quest_step" => params}) do
    case Quest.update_step(id, params) do
      {:ok, step} ->
        redirect(conn,
          to: ~p"/admin/quests/#{step.quest_id}",
          flash: [info: "Step updated."]
        )

      {:error, changeset} ->
        step = Quest.get_step(id)

        render(conn, :edit,
          step: step,
          quest: step.quest,
          changeset: changeset
        )
    end
  end

  @doc """
  Deletes a quest step.
  """
  def delete(conn, %{"id" => id}) do
    case Quest.delete_step(id) do
      {:ok, step} ->
        redirect(conn,
          to: ~p"/admin/quests/#{step.quest_id}",
          flash: [info: "Step removed."]
        )

      {:error, _changeset} ->
        step = Quest.get_step(id)

        redirect(conn,
          to: ~p"/admin/quests/#{step.quest_id}",
          flash: [error: "There was an issue removing the step. Please try again."]
        )
    end
  end
end
