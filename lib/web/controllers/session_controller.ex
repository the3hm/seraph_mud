defmodule Web.SessionController do
  @moduledoc """
  Handles user login and logout.
  """

  use Web, :controller

  alias Web.User

  @doc """
  Renders the login form.
  """
  def new(conn, _params) do
    render(conn, :new)
  end

  @doc """
  Authenticates and signs in the user.
  """
  def create(conn, %{"user" => %{"name" => name, "password" => password}}) do
    case User.find_and_validate(name, password) do
      {:error, :invalid} ->
        conn
        |> put_flash(:error, "Invalid sign in")
        |> redirect(to: ~p"/session/new")

      user ->
        conn
        |> put_session(:user_token, user.token)
        |> after_sign_in_redirect()
    end
  end

  @doc """
  Logs the user out by clearing the session.
  """
  def delete(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: ~p"/")
  end

  defp after_sign_in_redirect(conn) do
    case get_session(conn, :last_path) do
      nil ->
        redirect(conn, to: ~p"/")

      path ->
        conn
        |> put_session(:last_path, nil)
        |> redirect(to: path)
    end
  end
end
