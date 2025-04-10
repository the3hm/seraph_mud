defmodule Web.Weather do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Weather
  alias Data.Repo
  alias Web.Pagination

  @doc """
  Get all weathers
  """
  @spec all(Keyword.t()) :: [Weather.t()]
  def all(opts \\ [])

  def all(alpha: true) do
    Weather
    |> order_by([c], c.name)
    |> Repo.all()
  end

  def all(opts) do
    opts = Enum.into(opts, %{})

    Weather
    |> order_by([c], c.id)
    |> Pagination.paginate(opts)
  end

  @doc """
  List out all weather for a select box
  """
  @spec weather_select() :: [{String.t(), integer()}]
  def weather_select() do
    Weather
    |> select([c], [c.name, c.id])
    |> order_by([c], c.id)
    |> Repo.all()
    |> Enum.map(&List.to_tuple/1)
  end

  @doc """
  Get a weather
  """
  @spec get(integer) :: [Weather.t()]
  def get(id) do
    Weather
    |> where([c], c.id == ^id)
    |> Repo.one()
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %Weather{} |> Weather.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(Weather.t()) :: map
  def edit(weather), do: weather |> Weather.changeset(%{})

  @doc """
  Create a weather
  """
  @spec create(map) :: {:ok, Weather.t()} | {:error, map}
  def create(params) do
    %Weather{}
    |> Weather.changeset(params)
    |> Repo.insert()
  end

  @doc """
  Update an zone
  """
  @spec update(integer, map) :: {:ok, Zone.t()} | {:error, map}
  def update(id, params) do
    id
    |> get()
    |> Weather.changeset(params)
    |> Repo.update()
  end
end
