defmodule Web.AccountController do
  @moduledoc """
  Handles user account management, including password and email updates.
  """

  use Web, :controller

  alias Web.User
  alias Web.Router.Helpers, as: Routes

  plug(Web.Plug.PublicEnsureUser)

  @doc """
  Shows the account settings page with an email changeset.
  """
  def show(%{assigns: %{current_user: user}} = conn, _params) do
    render(conn, "show.html", email_changeset: User.email_changeset(user))
  end

  @doc """
  Updates the user's password when `current_password` is provided.
  """
  def update(%{assigns: %{current_user: user}} = conn, %{
        "user" => %{"current_password" => current_password} = params
      }) do
    case User.change_password(user, current_password, params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password updated")
        |> redirect(to: Routes.public_account_path(conn, :show))

      _ ->
        conn
        |> put_flash(:error, "Could not update your password")
        |> redirect(to: Routes.public_account_path(conn, :show))
    end
  end

  @doc """
  Updates the user's email if no password change is attempted.
  """
  def update(%{assigns: %{current_user: user}} = conn, %{"user" => params}) do
    case User.change_email(user, params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Email updated!")
        |> redirect(to: Routes.public_account_path(conn, :show))

      _ ->
        conn
        |> put_flash(:info, "There was an issue updating your email. Please try again.")
        |> redirect(to: Routes.public_account_path(conn, :show))
    end
  end
end
