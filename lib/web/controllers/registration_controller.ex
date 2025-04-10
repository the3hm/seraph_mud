defmodule Web.RegistrationController do
  @moduledoc """
  Handles user registration, including new account creation and finalizing character setup.
  """

  use Web, :controller

  alias Game.Config
  alias Web.User
  alias Web.Router.Helpers, as: Routes

  plug Web.Plug.PublicEnsureUser when action in [:finalize, :update]
  plug :ensure_registration_enabled?

  @doc """
  Renders the registration form.
  """
  def new(conn, _params) do
    render(conn, "new.html",
      changeset: User.new(),
      names: Config.random_character_names()
    )
  end

  @doc """
  Creates a new user account and logs them in.
  """
  def create(conn, %{"user" => params}) do
    case User.create(params) do
      {:ok, user, _character} ->
        conn
        |> put_session(:user_token, user.token)
        |> redirect(to: Routes.public_play_path(conn, :show))

      {:error, changeset} ->
        render(conn, "new.html",
          changeset: changeset,
          names: Config.random_character_names()
        )
    end
  end

  @doc """
  Shows the finalize registration page if required.
  """
  def finalize(%{assigns: %{current_user: user}} = conn, _params) do
    if User.finalize_registration?(user) do
      render(conn, "finalize.html", changeset: User.finalize(user))
    else
      redirect(conn, to: Routes.public_page_path(conn, :index))
    end
  end

  @doc """
  Updates the user during finalization.
  """
  def update(%{assigns: %{current_user: user}} = conn, %{"user" => params}) do
    cond do
      User.finalize_registration?(user) &&
        match?({:ok, _}, User.finalize_user(user, params)) ->
        redirect(conn, to: Routes.public_page_path(conn, :index))

      {:error, changeset} = User.finalize_user(user, params) ->
        render(conn, "finalize.html", changeset: changeset)

      true ->
        redirect(conn, to: Routes.public_page_path(conn, :index))
    end
  end

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
