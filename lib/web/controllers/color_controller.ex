defmodule Web.ColorController do
  @moduledoc """
  Serves color CSS stylesheets for clients and homepage use.
  """

  use Web, :controller

  alias Web.ColorCode

  @doc """
  Renders a CSS file with game color codes, used by clients and the homepage.
  """
  def index(conn, params) do
    is_client = Map.get(params, "client", false)
    is_home = Map.get(params, "home", false)

    conn
    |> put_resp_header("content-type", "text/css")
    |> put_resp_header("cache-control", "public, max-age=86400")
    |> render(:index,
      is_client: is_client,
      is_home: is_home,
      color_codes: ColorCode.all()
    )
  end
end
