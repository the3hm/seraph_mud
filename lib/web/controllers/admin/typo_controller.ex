defmodule Web.Admin.TypoController do
  @moduledoc """
  Admin controller for managing user-submitted typos.
  Supports listing and viewing typos.
  """

  use Web.AdminController

  alias Web.Router.Helpers, as: Routes
  alias Web.Typo

  plug Web.Plug.FetchPage when action in [:index]

  @doc """
  Lists all typos with pagination.
  """
  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns
    %{page: typos, pagination: pagination} = Typo.all(page: page, per: per)

    render(conn, "index.html",
      typos: typos,
      pagination: pagination
    )
  end

  @doc """
  Displays a single typo.
  """
  def show(conn, %{"id" => id}) do
    render(conn, "show.html", typo: Typo.get(id))
  end
end
