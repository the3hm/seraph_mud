defmodule Web.AuthController do
  @moduledoc """
  Handles OAuth login via Grapevine.
  """

  use Web, :controller

  plug(Ueberauth)

  alias Web.User

  def request(conn, _params) do
    conn
    |> put_flash(:error, "There was an error authenticating.")
    |> redirect(to: ~p"/")
  end

  def callback(%{assigns: %{ueberauth_failure: failure}} = conn, _params) do
    message =
      failure.errors
      |> Enum.map(& &1.message)
      |> Enum.join(", ")

    conn
    |> put_flash(:error, message)
    |> redirect(to: ~p"/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case User.from_grapevine(auth) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> put_session(:user_token, user.token)
        |> redirect(to: ~p"/")

      {:ok, :finalize_registration, user} ->
        conn
        |> put_flash(:info, "Please finish registration.")
        |> put_session(:user_token, user.token)
        |> redirect(to: ~p"/register/finalize")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem signing in. Please contact an administrator.")
        |> redirect(to: ~p"/")
    end
  end
end
