defmodule Web.Admin.SessionController do
  @moduledoc """
  Handles admin sign-in sessions.
  """

  use Web, :controller

  plug(:put_layout, "login.html")

  alias Web.User

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"user" => %{"name" => name, "password" => password}}) do
    case User.find_and_validate(name, password) do
      {:error, :invalid} ->
        redirect(conn,
          to: ~p"/admin/session/new",
          flash: [error: "Invalid sign in"]
        )

      user ->
        conn
        |> put_session(:user_token, user.token)
        |> redirect(to: ~p"/admin/dashboard")
    end
  end
end
