defmodule Data.Room.Weather do
  @moduledoc """
  A weather of a room
  """

  @behaviour Ecto.Type

  import Ecto.Changeset

  defstruct [:id, :key, :short_description, :description, :listen]

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(weather) when is_map(weather), do: {:ok, weather}
  def cast(_), do: :error

  @impl Ecto.Type
  @doc """
  Load an item weather from the database

      iex> {:ok, weather} = Data.Room.Weather.load(%{"key" => "log"})
      iex> weather.key
      "log"
  """
  def load(weather = %__MODULE__{}), do: {:ok, weather}

  def load(weather) do
    weather = for {key, val} <- weather, into: %{}, do: {String.to_atom(key), val}
    weather = ensure_id(weather)
    {:ok, struct(__MODULE__, weather)}
  end

  defp ensure_id(weather) do
    case Map.has_key?(weather, :id) do
      true -> weather
      false -> Map.put(weather, :id, UUID.uuid4())
    end
  end

  @impl Ecto.Type
  def dump(weather) when is_map(weather), do: {:ok, Map.delete(weather, :__struct__)}
  def dump(_), do: :error

  @impl true
  def embed_as(_), do: :self

  @impl true
  def equal?(term1, term2), do: term1 == term2

  def validate_weathers(changeset) do
    case get_field(changeset, :weathers) do
      nil ->
        changeset

      weathers ->
        case Enum.all?(weathers, &valid?/1) do
          true -> changeset
          false -> add_error(changeset, :weathers, "is invalid")
        end
    end
  end

  def valid?(weather) do
    weather.id != "" && !is_nil(weather.id) && weather.key != "" && !is_nil(weather.key) &&
      weather.description != "" && !is_nil(weather.description) && weather.short_description != "" &&
      !is_nil(weather.short_description)
  end
end