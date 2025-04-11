defmodule Web.ChatController do
  @moduledoc """
  Displays the in-game chat interface for authenticated characters.
  """

  use Web, :controller

  alias Web.Router.Helpers, as: Routes

  plug(Web.Plug.PublicEnsureUser)
  plug(Web.Plug.PublicEnsureCharacter)

  @doc """
  Renders the in-game chat interface.
  """
  def show(conn, _params) do
    render(conn, "show.html")
  end
end
