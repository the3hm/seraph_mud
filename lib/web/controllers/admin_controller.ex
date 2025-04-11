defmodule Web.AdminController do
  @moduledoc """
  Shared controller logic for the admin section.

  Provides plug helpers for authentication and role enforcement:
  - `ensure_user!/2`
  - `ensure_at_least_builder!/2`
  - `ensure_admin!/2`
  """

  alias Data.User

  import Plug.Conn
  import Phoenix.Controller
  alias Web.Router.Helpers, as: Routes

  use Phoenix.VerifiedRoutes, endpoint: Web.Endpoint, router: Web.Router

  @doc """
  Injects admin-specific controller behavior, including layout and permission checks.
  """
  defmacro __using__(_opts) do
    quote do
      use Web, :controller

      import Web.AdminController,
        only: [
          ensure_user!: 2,
          ensure_at_least_builder!: 2,
          ensure_admin!: 2
        ]

      plug(:put_layout, "admin.html")
      plug(Web.Plug.LoadUser)
      plug(Web.Plug.LoadCharacter)
      plug(:ensure_user!)
      plug(:ensure_at_least_builder!)
    end
  end

  @doc """
  Ensures a user is signed in before continuing.
  """
  def ensure_user!(conn, _opts) do
    if Map.has_key?(conn.assigns, :current_user) do
      conn
    else
      conn
      |> redirect(to: Routes.session_path(conn, :new))
      |> halt()
    end
  end

  @doc """
  Allows access only to builders or admins.
  """
  def ensure_at_least_builder!(%{assigns: %{current_user: user}} = conn, _opts) do
    if User.is_admin?(user) or User.is_builder?(user) do
      conn
    else
      conn
      |> redirect(to: Routes.public_page_path(conn, :index))
      |> halt()
    end
  end

  @doc """
  Allows access only to full admins.
  """
  def ensure_admin!(%{assigns: %{current_user: user}} = conn, _opts) do
    if User.is_admin?(user) do
      conn
    else
      conn
      |> redirect(to: Routes.admin_dashboard_path(conn, :index))  # Correct path here
      |> halt()
    end
  end
end
