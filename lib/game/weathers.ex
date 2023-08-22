defmodule Game.Weathers do
  @moduledoc """
  Agent for keeping track of weathers in the system
  """

  use GenServer

  alias Data.Weather
  alias Data.Repo

  @key :weathers

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Load a weather
  """
  def weather(id) when is_integer(id) do
    case Cachex.get(@key, id) do
      {:ok, weather} when weather != nil ->
        weather

      _ ->
        nil
    end
  end

  @doc """
  Convert a list of weather ids to a list of weathers
  """
  @spec weathers([integer()]) :: [Weather.t()]
  def weathers(ids) do
    ids
    |> Enum.map(&weather/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Insert a new weather into the cache
  """
  @spec insert(Weather.t()) :: :ok
  def insert(weather) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.call(member, {:insert, weather})
    end)
  end

  @doc """
  Reload a weather in the cache
  """
  @spec reload(Weather.t()) :: :ok
  def reload(weather), do: insert(weather)

  @doc """
  Remove a weather from the cache
  """
  def remove(weather) do
    members = :pg2.get_members(@key)

    Enum.map(members, fn member ->
      GenServer.call(member, {:remove, weather})
    end)
  end

  @doc """
  For testing only: clear the EST table
  """
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  #
  # Server
  #

  def init(_) do
    :ok = :pg2.create(@key)
    :ok = :pg2.join(@key, self())

    {:ok, %{}, {:continue, :load_weathers}}
  end

  def handle_continue(:load_weathers, state) do
    weathers = Repo.all(Weather)

    Enum.each(weathers, fn weather ->
      Cachex.put(@key, weather.id, weather)
    end)

    {:noreply, state}
  end

  def handle_call({:insert, weather}, _from, state) do
    Cachex.put(@key, weather.id, weather)
    {:reply, :ok, state}
  end

  def handle_call({:remove, weather}, _from, state) do
    Cachex.del(@key, weather.id)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    Cachex.clear(@key)
    {:reply, :ok, state}
  end
end
