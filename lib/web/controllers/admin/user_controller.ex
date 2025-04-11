defmodule Web.Admin.UserController do
  @moduledoc """
  Admin-only controller for managing users.
  Includes full pagination, filtering, editing, and viewing.
  """

  use Web.AdminController

  alias Web.Router.Helpers, as: Routes
  alias Web.User

  plug(Web.Plug.FetchPage when action in [:index])
  plug(:ensure_admin!)

  @doc """
  Lists all users with filters and pagination.
  """
  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "user", %{})

    %{page: users, pagination: pagination} =
      User.all(filter: filter, page: page, per: per)

    render(conn, "index.html",
      users: users,
      filter: filter,
      pagination: pagination
    )
  end

  @doc """
  Displays a single user’s profile.
  """
  def show(conn, %{"id" => id}) do
    render(conn, "show.html", user: User.get(id))
  end

  @doc """
  Renders the edit form for a user.
  """
  def edit(conn, %{"id" => id}) do
    user = User.get(id)

    render(conn, "edit.html",
      user: user,
      changeset: User.edit(user)
    )
  end

  @doc """
  Updates a user's data (e.g. email, role).
  """
  def update(conn, %{"id" => id, "user" => params}) do
    case User.update(id, params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "#{user.name} updated!")
        |> redirect(to: Routes.admin_user_path(conn, :show, user.id))

      {:error, changeset} ->
        user = User.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{user.name}. Please try again.")
        |> render("edit.html",
          user: user,
          changeset: changeset
        )
    end
  end
end
