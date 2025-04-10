defmodule Web.Admin.SessionController do
  @moduledoc """
  Handles admin sign-in sessions.
  """

  use Web, :controller

  plug(:put_layout, "login.html")

  alias Web.User
  alias Web.Router.Helpers, as: Routes

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => %{"name" => name, "password" => password}}) do
    case User.find_and_validate(name, password) do
      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Invalid sign in")
        |> redirect(to: Routes.session_path(conn, :new))

      user ->
        conn
        |> put_session(:user_token, user.token)
        |> redirect(to: Routes.dashboard_path(conn, :index))
    end
  end
end
