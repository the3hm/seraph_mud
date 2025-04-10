defmodule Web.AccountTwoFactorController do
  @moduledoc """
  Handles setup, verification, and management of two-factor authentication (TOTP) for user accounts.
  """

  use Web, :controller

  alias Web.User
  alias Web.Router.Helpers, as: Routes

  @failed_attempts_limit 3

  plug Web.Plug.PublicEnsureUser
  plug :signout_after_failed_attempts when action in [:verify, :verify_token]
  plug :ensure_not_verified_yet! when action in [:start, :validate, :qr]

  @doc """
  Starts the two-factor setup process and generates a new TOTP secret.
  """
  def start(%{assigns: %{current_user: user}} = conn, _params) do
    user = User.create_totp_secret(user)
    render(conn, "start.html", user: user)
  end

  @doc """
  Validates a user's TOTP token during setup.
  """
  def validate(%{assigns: %{current_user: user}} = conn, %{"user" => %{"token" => token}}) do
    if User.valid_totp_token?(user, token) do
      User.totp_token_verified(user)

      conn
      |> put_flash(:info, "Your account has Two Factor security enabled!")
      |> put_session(:is_user_totp_verified, true)
      |> redirect(to: Routes.public_account_path(conn, :show))
    else
      conn
      |> put_flash(:error, "Token was invalid. Try again.")
      |> redirect(to: Routes.public_account_two_factor_path(conn, :start))
    end
  end

  @doc """
  Displays the verification form for existing users.
  """
  def verify(conn, _params) do
    render(conn, "verify.html")
  end

  @doc """
  Attempts to verify a TOTP token at login.
  """
  def verify_token(%{assigns: %{current_user: user}} = conn, %{"user" => %{"token" => token}}) do
    if User.valid_totp_token?(user, token) do
      conn
      |> put_session(:is_user_totp_verified, true)
      |> redirect(to: Routes.public_page_path(conn, :index))
    else
      failed_count = get_session(conn, :totp_failed_count) || 0

      conn
      |> put_flash(:error, "Token was invalid. Try again.")
      |> put_session(:totp_failed_count, failed_count + 1)
      |> redirect(to: Routes.public_account_two_factor_path(conn, :verify))
    end
  end

  @doc """
  Disables TOTP and clears session verification.
  """
  def clear(%{assigns: %{current_user: user}} = conn, _params) do
    User.reset_totp(user)

    conn
    |> put_session(:is_user_totp_verified, false)
    |> put_flash(:info, "Second factor disabled")
    |> redirect(to: Routes.public_account_path(conn, :show))
  end

  @doc """
  Generates the QR code PNG image for TOTP apps.
  """
  def qr(%{assigns: %{current_user: user}} = conn, _params) do
    png = User.generate_qr_png(user)

    conn
    |> put_resp_header("content-type", "image/png")
    |> put_resp_header("cache-control", "private")
    |> send_resp(200, png)
  end

  @doc """
  If the user exceeds the maximum failed TOTP attempts, sign them out.
  """
  def signout_after_failed_attempts(conn, _opts) do
    case get_session(conn, :totp_failed_count) do
      @failed_attempts_limit ->
        conn
        |> clear_session()
        |> put_flash(:error, "You reached max token attempts")
        |> redirect(to: Routes.public_page_path(conn, :index))
        |> halt()

      _ ->
        conn
    end
  end

  @doc """
  Prevents restarting or showing the QR setup page if the user is already verified.
  """
  def ensure_not_verified_yet!(%{assigns: %{current_user: user}} = conn, _opts) do
    case user.totp_verified_at do
      nil -> conn
      _ ->
        conn
        |> redirect(to: Routes.public_page_path(conn, :index))
        |> halt()
    end
  end
end
