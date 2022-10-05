defmodule Web.Item do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query
  import Web.KeywordsHelper

  alias Data.Effect
  alias Data.Item
  alias Data.Stats
  alias Data.Repo
  alias Web.Filter
  alias Web.Pagination

  @behaviour Filter

  @doc """
  Delegate to the Data item for types
  """
  @spec types() :: [String.t()]
  def types(), do: Item.types()

  @doc """
  Load all items
  """
  @spec all(opts :: Keyword.t()) :: [Item.t()]
  def all(opts \\ []) do
    opts = Enum.into(opts, %{})

    Item
    |> order_by([i], i.id)
    |> preload([:item_aspects])
    |> Filter.filter(opts[:filter], __MODULE__)
    |> Pagination.paginate(opts)
  end

  @impl Filter
  def filter_on_attribute({"cost_from", cost}, query) do
    query |> where([i], i.cost >= ^cost)
  end

  def filter_on_attribute({"cost_to", cost}, query) do
    query |> where([i], i.cost <= ^cost)
  end

  def filter_on_attribute({"level_from", level}, query) do
    query |> where([i], i.level >= ^level)
  end

  def filter_on_attribute({"level_to", level}, query) do
    query |> where([i], i.level <= ^level)
  end

  def filter_on_attribute({"tag", value}, query) do
    query
    |> where([n], fragment("? @> ?::varchar[]", n.tags, [^value]))
  end

  def filter_on_attribute({"type", type}, query) do
    query |> where([i], i.type == ^type)
  end

  def filter_on_attribute({"name", name}, query) do
    query
    |> where([c], ilike(c.name, ^"%#{name}%"))
  end

  def filter_on_attribute({"item_aspect_id", item_aspect_id}, query) do
    query
    |> join(:left, [i], ia in assoc(i, :item_aspectings))
    |> where([i, ia], ia.item_aspect_id == ^item_aspect_id)
  end

  @doc """
  List out all items for a select box
  """
  @spec for_select() :: [{String.t(), integer()}]
  def for_select() do
    Item
    |> select([i], [i.name, i.id])
    |> order_by([i], i.id)
    |> Repo.all()
    |> Enum.map(&List.to_tuple/1)
  end

  @doc """
  Get a single item
  """
  @spec get(id :: integer) :: Item.t()
  def get(id) do
    Item
    |> Repo.get(id)
    |> Repo.preload(shop_items: [:shop], npc_items: [:npc], item_aspectings: [:item_aspect])
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %Item{} |> Item.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(item :: Item.t()) :: changeset :: map
  def edit(item), do: item |> Item.changeset(%{})

  @doc """
  Clone an item (remove the id)
  """
  @spec clone(item :: Item.t()) :: changeset :: map
  def clone(item) do
    item = item |> Map.take(Item.fields())
    struct(Item, item)
  end

  @doc """
  Create an item
  """
  @spec create(params :: map) :: {:ok, Item.t()} | {:error, changeset :: map}
  def create(params) do
    %Item{}
    |> Item.changeset(cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Update an item
  """
  @spec update(id :: integer, params :: map) :: {:ok, Item.t()} | {:error, changeset :: map}
  def update(id, params) do
    id
    |> get()
    |> Item.changeset(cast_params(params))
    |> Repo.update()
  end

  @doc """
  Cast params into what `Data.Item` expects
  """
  @spec cast_params(params :: map) :: map
  def cast_params(params) do
    params
    |> split_keywords()
    |> parse_stats()
    |> parse_effects()
    |> parse_tags()
  end

  defp parse_stats(params = %{"stats" => stats}) do
    case Poison.decode(stats) do
      {:ok, stats} -> stats |> cast_stats(params)
      _ -> params
    end
  end

  defp parse_stats(params), do: params

  defp cast_stats(stats, params) do
    case stats |> Stats.load() do
      {:ok, stats} ->
        Map.put(params, "stats", stats)

      _ ->
        params
    end
  end

  defp parse_effects(params = %{"effects" => effects}) do
    case Poison.decode(effects) do
      {:ok, effects} -> effects |> cast_effects(params)
      _ -> params
    end
  end

  defp parse_effects(params), do: params

  defp cast_effects(effects, params) do
    effects =
      effects
      |> Enum.map(fn effect ->
        case Effect.load(effect) do
          {:ok, effect} -> effect
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    Map.put(params, "effects", effects)
  end

  def parse_tags(params = %{"tags" => tags}) do
    tags =
      tags
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    params
    |> Map.put("tags", tags)
  end

  def parse_tags(params), do: params
end
