defmodule Web.Race do
  @moduledoc """
  Bounded context for the Phoenix app talking to the data layer
  """

  import Ecto.Query

  alias Data.Race
  alias Data.RaceSkill
  alias Data.Repo
  alias Data.Stats

  @doc """
  Get all races
  """
  @spec all(opts :: Keyword.t()) :: [Race.t()]
  def all(opts \\ [])

  def all(alpha: true) do
    Race
    |> order_by([r], r.name)
    |> Repo.all()
  end

  def all(_) do
    Race
    |> order_by([r], r.id)
    |> Repo.all()
  end

  @doc """
  List out all races for a select box
  """
  @spec race_select() :: [{String.t(), integer()}]
  def race_select() do
    Race
    |> select([r], [r.name, r.id])
    |> order_by([r], r.id)
    |> Repo.all()
    |> Enum.map(&List.to_tuple/1)
  end

  @doc """
  Get a races
  """
  @spec get(id :: integer) :: [Race.t()]
  def get(id) do
    Race
    |> where([c], c.id == ^id)
    |> preload(
      race_skills:
        ^from(cs in RaceSkill, left_join: s in assoc(cs, :skill), order_by: [s.level, s.id])
    )
    |> preload(race_skills: [:skill])
    |> Repo.one()
  end

  @doc """
  Get a changeset for a new page
  """
  @spec new() :: changeset :: map
  def new(), do: %Race{} |> Race.changeset(%{})

  @doc """
  Get a changeset for an edit page
  """
  @spec edit(race :: Race.t()) :: changeset :: map
  def edit(race), do: race |> Race.changeset(%{})

  @doc """
  Create a race
  """
  @spec create(params :: map) :: {:ok, Race.t()} | {:error, changeset :: map}
  def create(params) do
    %Race{}
    |> Race.changeset(cast_params(params))
    |> Repo.insert()
  end

  @doc """
  Update a race
  """
  @spec update(id :: integer, params :: map) :: {:ok, Race.t()} | {:error, changeset :: map}
  def update(id, params) do
    id
    |> get()
    |> Race.changeset(cast_params(params))
    |> Repo.update()
  end

  @doc """
  Cast params into what `Data.Race` expects
  """
  @spec cast_params(params :: map) :: map
  def cast_params(params) do
    params
    |> parse_stats()
  end

  defp parse_stats(params = %{"starting_stats" => stats}) do
    case Jason
.decode(stats) do
      {:ok, stats} -> stats |> cast_stats(params)
      _ -> params
    end
  end

  defp parse_stats(params), do: params

  defp cast_stats(stats, params) do
    case stats |> Stats.load() do
      {:ok, stats} ->
        Map.put(params, "starting_stats", stats)

      _ ->
        params
    end
  end

  #
  # Race Skills
  #

  @doc """
  New changeset
  """
  @spec new_race_skill(Race.t()) :: Ecto.Changeset.t()
  def new_race_skill(race) do
    race
    |> Ecto.build_assoc(:race_skills)
    |> RaceSkill.changeset(%{})
  end

  def add_skill(race, skill_id) do
    race
    |> Ecto.build_assoc(:race_skills)
    |> RaceSkill.changeset(%{skill_id: skill_id})
    |> Repo.insert()
  end

  def remove_skill(id) do
    case Repo.get(RaceSkill, id) do
      nil -> {:error, :not_found}
      race_skill -> Repo.delete(race_skill)
    end
  end
end
