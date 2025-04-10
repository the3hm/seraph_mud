defmodule Web.AnnouncementController do
  @moduledoc """
  Public-facing controller for viewing announcements.
  """

  use Web, :controller

  alias Web.Announcement
  alias Web.Router.Helpers, as: Routes

  plug(:fetch_announcement when action in [:show])
  plug(:check_published when action in [:show])

  @doc """
  Renders the announcement feed in XML format.
  """
  def feed(conn, _params) do
    announcements = Announcement.recent(sticky: false)
    render(conn, "feed.xml", announcements: announcements)
  end

  @doc """
  Shows a single announcement.
  """
  def show(conn, _params) do
    render(conn, "show.html")
  end

  def fetch_announcement(conn, _opts) do
    with %{"id" => uuid} <- conn.params,
         %{} = announcement <- Announcement.get_by_uuid(uuid) do
      assign(conn, :announcement, announcement)
    else
      _ -> redirect_home(conn)
    end
  end

  def check_published(%{assigns: %{announcement: %{is_published: true}}} = conn, _opts), do: conn
  def check_published(conn, _opts), do: maybe_redirect_home(conn)

  defp maybe_redirect_home(conn) do
    user = conn.assigns[:user]

    if user && "admin" in user.flags do
      conn
    else
      redirect_home(conn)
    end
  end

  defp redirect_home(conn) do
    conn
    |> redirect(to: Routes.public_page_path(conn, :index))
    |> halt()
  end
end
