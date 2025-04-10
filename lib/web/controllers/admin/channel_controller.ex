defmodule Web.Admin.ChannelController do
  @moduledoc """
  Admin controller for managing communication channels in the game.
  """

  use Web.AdminController

  alias Web.Channel

  plug :ensure_admin!

  @doc """
  Lists all channels.
  """
  def index(conn, _params) do
    channels = Channel.all()

    conn
    |> assign(:channels, channels)
    |> render("index.html")
  end

  @doc """
  Shows details of a single channel.
  """
  def show(conn, %{"id" => id}) do
    channel = Channel.get(id)

    conn
    |> assign(:channel, channel)
    |> render("show.html")
  end

  @doc """
  Displays a form for creating a new channel.
  """
  def new(conn, _params) do
    changeset = Channel.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  @doc """
  Handles channel creation.
  """
  def create(conn, %{"channel" => params}) do
    case Channel.create(params) do
      {:ok, channel} ->
        conn
        |> put_flash(:info, "#{channel.name} created!")
        |> redirect(to: channel_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the channel. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  @doc """
  Displays the edit form for an existing channel.
  """
  def edit(conn, %{"id" => id}) do
    channel = Channel.get(id)
    changeset = Channel.edit(channel)

    conn
    |> assign(:channel, channel)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  @doc """
  Handles channel updates.
  """
  def update(conn, %{"id" => id, "channel" => params}) do
    channel = Channel.get(id)

    case Channel.update(channel, params) do
      {:ok, _channel} ->
        conn
        |> put_flash(:info, "#{channel.name} updated!")
        |> redirect(to: channel_path(conn, :index))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue updating #{channel.name}. Please try again.")
        |> assign(:channel, channel)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
