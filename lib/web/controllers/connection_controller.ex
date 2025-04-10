defmodule Web.ConnectionController do
  @moduledoc """
  Handles character connection authorization from the Telnet/MUD client.
  """

  use Web, :controller

  alias Web.User
  alias Web.Router.Helpers, as: Routes

  plug Web.Plug.PublicEnsureUser

  @doc """
  Displays the authorization page for a Telnet session.
  """
  def authorize(conn, %{"id" => id}) do
    render(conn, "authorize.html", telnet_id: id)
  end

  @doc """
  Authorizes a Telnet/MUD connection and signs the user in.
  """
  def connect(%{assigns: %{current_character: character}} = conn, %{"id" => id}) do
    User.authorize_connection(character, id)

    conn
    |> put_flash(:info, "Connection authorized, you are signed in!")
    |> redirect(to: Routes.public_page_path(conn, :index))
  end
end
