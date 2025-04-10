defmodule Web.Admin.DashboardController do
  @moduledoc """
  Admin dashboard controller.

  Displays a summary view including connected players and recent announcements.
  """

  use Web.AdminController

  alias Web.Announcement
  alias Web.User

  @doc """
  Loads the admin dashboard with online users and recent announcements.
  """
  def index(conn, _params) do
    players = User.connected_players()
    announcements = Announcement.recent()

    conn
    |> assign(:players, players)
    |> assign(:announcements, announcements)
    |> render("index.html")
  end
end
