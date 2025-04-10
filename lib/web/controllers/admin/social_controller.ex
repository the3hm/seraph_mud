defmodule Web.Admin.SocialController do
  @moduledoc """
  Admin controller for managing socials (emotes and chat commands).
  Supports listing, filtering, creation, editing, and viewing.
  """

  use Web.AdminController

  alias Web.Router.Helpers, as: Routes
  alias Web.Social

  plug Web.Plug.FetchPage when action in [:index]

  @doc """
  Lists all socials with optional filters and pagination.
  """
  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "social", %{})

    %{page: socials, pagination: pagination} =
      Social.all(filter: filter, page: page, per: per)

    render(conn, "index.html",
      socials: socials,
      filter: filter,
      pagination: pagination
    )
  end

  @doc """
  Shows a single social entry.
  """
  def show(conn, %{"id" => id}) do
    render(conn, "show.html", social: Social.get(id))
  end

  @doc """
  Renders the form to create a new social.
  """
  def new(conn, _params) do
    render(conn, "new.html", changeset: Social.new())
  end

  @doc """
  Creates a new social entry.
  """
  def create(conn, %{"social" => params}) do
    case Social.create(params) do
      {:ok, social} ->
        conn
        |> put_flash(:info, "Created #{social.name}!")
        |> redirect(to: Routes.admin_social_path(conn, :show, social.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the social. Please try again.")
        |> render("new.html", changeset: changeset)
    end
  end

  @doc """
  Renders the form to edit an existing social.
  """
  def edit(conn, %{"id" => id}) do
    social = Social.get(id)

    render(conn, "edit.html",
      social: social,
      changeset: Social.edit(social)
    )
  end

  @doc """
  Updates a social entry.
  """
  def update(conn, %{"id" => id, "social" => params}) do
    social = Social.get(id)

    case Social.update(social, params) do
      {:ok, social} ->
        conn
        |> put_flash(:info, "Updated #{social.name}!")
        |> redirect(to: Routes.admin_social_path(conn, :show, social.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem updating #{social.name}. Please try again.")
        |> render("edit.html",
          social: social,
          changeset: changeset
        )
    end
  end
end
