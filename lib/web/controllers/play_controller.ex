defmodule Web.PlayController do
  @moduledoc """
  Handles the main game play interface and layout switching.
  """

  use Web, :controller

  plug(Web.Plug.PublicEnsureUser)
  plug(Web.Plug.PublicEnsureCharacter)
  plug(:put_layout, "play.html")

  alias Web.Router.Helpers, as: Routes

  @doc """
  Renders the standard play interface.
  """
  def show(conn, _params) do
    render(conn, "show.html")
  end

  @doc """
  Renders the React-based play interface.
  """
  def show_react(conn, _params) do
    conn
    |> put_layout("play_react.html")
    |> render("show_react.html")
  end
end
