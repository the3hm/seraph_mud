defmodule Web.Admin.CharacterController do
  @moduledoc """
  Admin controller for viewing, managing, and teleporting characters.
  """

  use Web.AdminController

  alias Web.Character

  plug Web.Plug.FetchPage when action in [:index]
  plug :ensure_admin!

  @doc """
  Displays a paginated list of characters with optional filters.
  """
  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "character", %{})

    %{page: characters, pagination: pagination} =
      Character.all(filter: filter, page: page, per: per)

    conn
    |> assign(:characters, characters)
    |> assign(:filter, filter)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  @doc """
  Shows details for a specific character.
  """
  def show(conn, %{"id" => id}) do
    with {:ok, character} <- Character.get(id) do
      conn
      |> assign(:character, character)
      |> render("show.html")
    end
  end

  @doc """
  Renders a character's live session view for admins.
  """
  def watch(conn, %{"character_id" => id}) do
    {:ok, character} = Character.get(id)

    conn
    |> assign(:character, character)
    |> render("watch.html")
  end

  @doc """
  Resets a character's session or state.
  """
  def reset(conn, %{"character_id" => id}) do
    Character.reset(id)

    redirect(conn, to: character_path(conn, :show, id))
  end

  @doc """
  Teleports the current character to the specified room.
  """
  def teleport(conn, %{"room_id" => room_id}) do
    %{current_character: character} = conn.assigns

    case Character.teleport(character, room_id) do
      {:ok, _character} -> redirect(conn, to: room_path(conn, :show, room_id))
      _ -> redirect(conn, to: room_path(conn, :show, room_id))
    end
  end

  @doc """
  Disconnects a specific character from their session.
  """
  def disconnect(conn, %{"character_id" => id}) do
    with {:ok, id} <- Ecto.Type.cast(:integer, id),
         :ok <- Character.disconnect(id) do
      redirect(conn, to: character_path(conn, :show, id))
    else
      _ ->
        redirect(conn, to: character_path(conn, :show, id))
    end
  end

  @doc """
  Disconnects all characters from active sessions.
  """
  def disconnect(conn, _params) do
    Character.disconnect()
    redirect(conn, to: dashboard_path(conn, :index))
  end
end
