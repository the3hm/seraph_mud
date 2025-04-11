defmodule Web.WhoController do
  @moduledoc """
  Displays a list of currently connected players.
  """

  use Web, :controller

  alias Web.User

  @doc """
  Renders the who list with all currently connected players.
  """
  def index(conn, _params) do
    render(conn, :index, players: User.connected_players())
  end
end
