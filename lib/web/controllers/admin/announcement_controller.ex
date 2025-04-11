defmodule Web.Admin.AnnouncementController do
  @moduledoc """
  Admin controller for managing in-game announcements.
  """

  use Web.AdminController

  alias Web.Announcement

  plug(Web.Plug.FetchPage when action in [:index])

  @doc """
  Displays a paginated list of announcements.
  """
  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: announcements, pagination: pagination} = Announcement.all(page: page, per: per)

    conn
    |> assign(:announcements, announcements)
    |> assign(:pagination, pagination)
    |> render(:index)
  end

  @doc """
  Displays a single announcement by ID.
  """
  def show(conn, %{"id" => id}) do
    announcement = Announcement.get(id)

    conn
    |> assign(:announcement, announcement)
    |> render(:show)
  end

  @doc """
  Renders the form to create a new announcement.
  """
  def new(conn, _params) do
    changeset = Announcement.new()

    conn
    |> assign(:changeset, changeset)
    |> render(:new)
  end

  @doc """
  Creates a new announcement.
  """
  def create(conn, %{"announcement" => params}) do
    case Announcement.create(params) do
      {:ok, announcement} ->
        conn
        |> put_flash(:info, "#{announcement.title} created!")
        |> redirect(to: ~p"/admin/announcements/#{announcement.id}")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the announcement. Please try again.")
        |> assign(:changeset, changeset)
        |> render(:new)
    end
  end

  @doc """
  Renders the form to edit an existing announcement.
  """
  def edit(conn, %{"id" => id}) do
    announcement = Announcement.get(id)
    changeset = Announcement.edit(announcement)

    conn
    |> assign(:announcement, announcement)
    |> assign(:changeset, changeset)
    |> render(:edit)
  end

  @doc """
  Updates an existing announcement.
  """
  def update(conn, %{"id" => id, "announcement" => params}) do
    case Announcement.update(id, params) do
      {:ok, announcement} ->
        conn
        |> put_flash(:info, "#{announcement.title} updated!")
        |> redirect(to: ~p"/admin/announcements/#{announcement.id}")

      {:error, changeset} ->
        announcement = Announcement.get(id)

        conn
        |> put_flash(
          :error,
          "There was a problem updating #{announcement.title}. Please try again."
        )
        |> assign(:announcement, announcement)
        |> assign(:changeset, changeset)
        |> render(:edit)
    end
  end
end
