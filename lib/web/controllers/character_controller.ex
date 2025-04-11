defmodule Web.CharacterController do
  @moduledoc """
  Handles character creation and swapping for signed-in users.
  """

  use Web, :controller

  alias Game.Config
  alias Web.Character
  alias Web.Router.Helpers, as: Routes

  plug(Web.Plug.PublicEnsureUser)

  @doc """
  Renders the new character creation form.
  """
  def new(conn, _params) do
    render(conn, "new.html",
      changeset: Character.new(),
      names: Config.random_character_names()
    )
  end

  @doc """
  Attempts to create a new character for the current user.
  """
  def create(%{assigns: %{current_user: user}} = conn, %{"character" => params}) do
    case Character.create(user, params) do
      {:ok, character} ->
        conn
        |> put_session(:current_character_id, character.id)
        |> redirect(to: Routes.public_play_path(conn, :show))

      {:error, changeset} ->
        render(conn, "new.html",
          changeset: changeset,
          names: Config.random_character_names()
        )
    end
  end

  @doc """
  Swaps the active character session to another owned by the user.
  """
  def swap(%{assigns: %{current_user: user}} = conn, %{"to" => id}) do
    case Character.get_character(user, id) do
      {:ok, character} ->
        conn
        |> put_session(:current_character_id, character.id)
        |> redirect_back()

      {:error, :not_found} ->
        redirect_back(conn)
    end
  end

  defp redirect_back(conn) do
    case get_req_header(conn, "referer") do
      [uri] ->
        uri = URI.parse(uri)
        redirect(conn, to: uri.path)

      _ ->
        redirect(conn, to: Routes.public_page_path(conn, :index))
    end
  end
end
