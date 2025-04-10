defmodule Web.Admin.QuestController do
  @moduledoc """
  Admin controller for managing quests.
  """

  use Web.AdminController

  alias Web.Quest
  alias Web.Router.Helpers, as: Routes

  plug Web.Plug.FetchPage when action in [:index]

  @doc """
  Lists all quests with optional filtering.
  """
  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "quest", %{})

    %{page: quests, pagination: pagination} =
      Quest.all(filter: filter, page: page, per: per)

    render(conn, "index.html",
      quests: quests,
      filter: filter,
      pagination: pagination
    )
  end

  @doc """
  Shows a specific quest.
  """
  def show(conn, %{"id" => id}) do
    quest = Quest.get(id)

    render(conn, "show.html", quest: quest)
  end

  @doc """
  Renders the form for creating a new quest.
  """
  def new(conn, _params) do
    render(conn, "new.html", changeset: Quest.new())
  end

  @doc """
  Creates a new quest.
  """
  def create(conn, %{"quest" => params}) do
    case Quest.create(params) do
      {:ok, quest} ->
        conn
        |> put_flash(:info, "#{quest.name} created!")
        |> redirect(to: Routes.admin_quest_path(conn, :show, quest.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the quest. Please try again.")
        |> render("new.html", changeset: changeset)
    end
  end

  @doc """
  Renders the edit form for a quest.
  """
  def edit(conn, %{"id" => id}) do
    quest = Quest.get(id)

    render(conn, "edit.html",
      quest: quest,
      changeset: Quest.edit(quest)
    )
  end

  @doc """
  Updates an existing quest.
  """
  def update(conn, %{"id" => id, "quest" => params}) do
    case Quest.update(id, params) do
      {:ok, quest} ->
        conn
        |> put_flash(:info, "#{quest.name} updated!")
        |> redirect(to: Routes.admin_quest_path(conn, :show, quest.id))

      {:error, changeset} ->
        quest = Quest.get(id)

        conn
        |> put_flash(:error, "There was a problem updating #{quest.name}. Please try again.")
        |> render("edit.html",
          quest: quest,
          changeset: changeset
        )
    end
  end
end
