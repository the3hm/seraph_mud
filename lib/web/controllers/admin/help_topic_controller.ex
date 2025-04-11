defmodule Web.Admin.HelpTopicController do
  @moduledoc """
  Admin controller for managing Help Topics.

  Provides interfaces to list, create, view, edit, and update help topics that appear in the in-game help system.
  """

  use Web.AdminController

  alias Web.HelpTopic

  plug(Web.Plug.FetchPage when action in [:index])

  @doc """
  List all help topics with pagination.
  """
  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: help_topics, pagination: pagination} = HelpTopic.all(page: page, per: per)

    render(conn, :index,
      help_topics: help_topics,
      pagination: pagination
    )
  end

  @doc """
  Show a specific help topic by ID.
  """
  def show(conn, %{"id" => id}) do
    help_topic = HelpTopic.get(id)
    render(conn, :show, help_topic: help_topic)
  end

  @doc """
  Render form to create a new help topic.
  """
  def new(conn, _params) do
    render(conn, :new, changeset: HelpTopic.new())
  end

  @doc """
  Handle creation of a new help topic.
  """
  def create(conn, %{"help_topic" => params}) do
    case HelpTopic.create(params) do
      {:ok, help_topic} ->
        redirect(conn,
          to: ~p"/admin/help_topics/#{help_topic.id}",
          flash: [info: "#{help_topic.name} created!"]
        )

      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          error_flash: "There was a problem creating the help topic. Please try again."
        )
    end
  end

  @doc """
  Render form to edit an existing help topic.
  """
  def edit(conn, %{"id" => id}) do
    help_topic = HelpTopic.get(id)
    render(conn, :edit, help_topic: help_topic, changeset: HelpTopic.edit(help_topic))
  end

  @doc """
  Handle updating of an existing help topic.
  """
  def update(conn, %{"id" => id, "help_topic" => params}) do
    case HelpTopic.update(id, params) do
      {:ok, help_topic} ->
        redirect(conn,
          to: ~p"/admin/help_topics/#{help_topic.id}",
          flash: [info: "#{help_topic.name} updated!"]
        )

      {:error, changeset} ->
        help_topic = HelpTopic.get(id)

        render(conn, :edit,
          help_topic: help_topic,
          changeset: changeset,
          error_flash: "There was an issue updating #{help_topic.name}. Please try again."
        )
    end
  end
end
