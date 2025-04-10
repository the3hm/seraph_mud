defmodule Web.Channel do
  @moduledoc """
  Context Module for talking to the in game channels
  """

  import Ecto.Query

  alias Data.Channel
  alias Data.ChannelMessage
  alias Data.Repo
  alias Game.Channels

  @doc """
  Get all channels active in the game
  """
  def all() do
    Channel
    |> order_by([c], c.name)
    |> Repo.all()
  end

  @doc """
  Get a channel
  """
  def get(id) do
    one_day_ago = Timex.now() |> Timex.shift(days: -1)

    Channel
    |> where([c], c.id == ^id)
    |> preload(
      messages:
        ^from(m in ChannelMessage, where: m.inserted_at > ^one_day_ago, order_by: [m.inserted_at])
    )
    |> Repo.one()
  end

  def recent_messages(channel) do
    ten_minutes_ago = Timex.now() |> Timex.shift(minutes: -10)

    ChannelMessage
    |> where([cm], cm.channel_id == ^channel.id)
    |> where([cm], cm.inserted_at >= ^ten_minutes_ago)
    |> order_by([cm], asc: cm.inserted_at)
    |> limit(10)
    |> Repo.all()
    |> Enum.map(fn message ->
      %{message: message.formatted}
    end)
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: map()
  def new(), do: %Channel{} |> Channel.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(Channel.t()) :: map()
  def edit(channel), do: channel |> Channel.changeset(%{})

  @doc """
  Create a channel
  """
  @spec create(map) :: {:ok, Channel.t()} | {:error, map}
  def create(params) do
    changeset = %Channel{} |> Channel.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, channel} ->
        Channels.insert(channel)
        maybe_subscribe_gossip(channel)
        {:ok, channel}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Update a channel's color
  """
  @spec update(Channel.t(), map()) :: {:ok, Channel.t()} | {:error, map}
  def update(channel, params) do
    changeset = channel |> Channel.changeset(params)

    case changeset |> Repo.update() do
      {:ok, updated_channel} ->
        Channels.reload(updated_channel)
        maybe_resubscribe_channel(channel, updated_channel)
        {:ok, updated_channel}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp maybe_subscribe_gossip(channel) do
    case channel.is_gossip_connected do
      true ->
        Gossip.subscribe(channel.gossip_channel)

      false ->
        :ok
    end
  end

  defp maybe_resubscribe_channel(old_channel, new_channel) do
    case new_channel.is_gossip_connected &&
           old_channel.gossip_channel != new_channel.gossip_channel do
      true ->
        if old_channel.gossip_channel, do: Gossip.unsubscribe(old_channel.gossip_channel)
        Gossip.subscribe(new_channel.gossip_channel)

      false ->
        if old_channel.is_gossip_connected, do: Gossip.unsubscribe(old_channel.gossip_channel)
    end
  end
end
