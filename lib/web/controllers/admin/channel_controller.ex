defmodule Web.Admin.ChannelController do
  @moduledoc """
  Admin controller for managing communication channels in the game.
  """

  use Web.AdminController

  alias Web.Channel

  plug(:ensure_admin!)

  @doc """
  Lists all channels.
  """
  def index(conn, _params) do
    channels = Channel.all()

    render(conn, :index, channels: channels)
  end

  @doc """
  Shows details of a single channel.
  """
  def show(conn, %{"id" => id}) do
    channel = Channel.get(id)

    render(conn, :show, channel: channel)
  end

  @doc """
  Displays a form for creating a new channel.
  """
  def new(conn, _params) do
    render(conn, :new, changeset: Channel.new())
  end

  @doc """
  Handles channel creation.
  """
  def create(conn, %{"channel" => params}) do
    case Channel.create(params) do
      {:ok, channel} ->
        redirect(conn,
          to: ~p"/admin/channels",
          flash: [info: "#{channel.name} created!"]
        )

      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          error_flash: "There was an issue creating the channel. Please try again."
        )
    end
  end

  @doc """
  Displays the edit form for an existing channel.
  """
  def edit(conn, %{"id" => id}) do
    channel = Channel.get(id)

    render(conn, :edit,
      channel: channel,
      changeset: Channel.edit(channel)
    )
  end

  @doc """
  Handles channel updates.
  """
  def update(conn, %{"id" => id, "channel" => params}) do
    channel = Channel.get(id)

    case Channel.update(channel, params) do
      {:ok, _channel} ->
        redirect(conn,
          to: ~p"/admin/channels",
          flash: [info: "#{channel.name} updated!"]
        )

      {:error, changeset} ->
        render(conn, :edit,
          channel: channel,
          changeset: changeset,
          error_flash: "There was an issue updating #{channel.name}. Please try again."
        )
    end
  end
end
