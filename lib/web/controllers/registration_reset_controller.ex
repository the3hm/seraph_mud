defmodule Web.RegistrationResetController do
  @moduledoc """
  Handles password reset via email and reset tokens.
  """

  use Web, :controller

  alias Game.Config
  alias Web.User
  alias Web.Router.Helpers, as: Routes

  plug :ensure_registration_enabled?

  @doc """
  Renders the password reset request form.
  """
  def new(conn, _params) do
    render(conn, "new.html", changeset: User.new())
  end

  @doc """
  Starts the password reset process.
  """
  def create(conn, %{"user" => %{"email" => email}}) do
    User.start_password_reset(email)

    conn
    |> put_flash(:info, "Password reset started!")
    |> redirect(to: Routes.public_session_path(conn, :new))
  end

  @doc """
  Renders the form to enter a new password using a reset token.
  """
  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html",
      token: token,
      changeset: User.new()
    )
  end

  @doc """
  Applies the password reset if the token and input are valid.
  """
  def update(conn, %{"token" => token, "user" => params}) do
    case User.reset_password(token, params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Password reset!")
        |> redirect(to: Routes.public_session_path(conn, :new))

      :error ->
        conn
        |> put_flash(:info, "There was an issue resetting.")
        |> redirect(to: Routes.public_session_path(conn, :new))
    end
  end

  @doc false
  def ensure_registration_enabled?(conn, _opts) do
    if Config.grapevine_only_login?() do
      conn
      |> redirect(to: Routes.public_session_path(conn, :new))
      |> halt()
    else
      conn
    end
  end
end
