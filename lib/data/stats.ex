defmodule Data.Stats do
  @moduledoc """
  Item statistics
  """

  import Data.Type

  @type character :: %{
          health_points: integer(),
          max_health_points: integer(),
          skill_points: integer(),
          max_skill_points: integer(),
          endurance_points: integer(),
          max_endurance_points: integer(),
          strength: integer(),
          agility: integer(),
          intelligence: integer(),
          awareness: integer(),
          vitality: integer(),
          willpower: integer()
        }
  @type armor :: %{
          slot: :atom
        }
  @type weapon :: %{}

  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(stats) when is_map(stats), do: {:ok, stats}
  def cast(_), do: :error

  @impl Ecto.Type
  def load(stats) do
    stats = for {key, val} <- stats, into: %{}, do: {String.to_atom(key), val}
    stats = Enum.into(stats, %{}, &cast_val/1)
    {:ok, stats}
  end

  defp cast_val({key, val}) do
    case key do
      :slot ->
        {key, String.to_atom(val)}

      _ ->
        {key, val}
    end
  end

  @impl Ecto.Type
  def dump(stats) when is_map(stats), do: {:ok, Map.delete(stats, :__struct__)}
  def dump(_), do: :error

  @impl true
  def embed_as(_), do: :self

  @impl true
  def equal?(term1, term2), do: term1 == term2

  @doc """
  Set defaults for new statistics

  A "migration" of stats to ensure new ones are always available. They should be
  saved back in after the user loads their account.
  """
  @spec default(Stats.t()) :: Stats.t()
  def default(stats) do
    stats
    |> migrate()
    |> ensure(:health_points, 50)
    |> ensure(:max_health_points, 50)
    |> ensure(:skill_points, 50)
    |> ensure(:max_skill_points, 50)
    |> ensure(:endurance_points, 20)
    |> ensure(:max_endurance_points, 20)
    |> ensure(:agility, 10)
    |> ensure(:awareness, 10)
    |> ensure(:intelligence, 10)
    |> ensure(:strength, 10)
    |> ensure(:vitality, 10)
    |> ensure(:willpower, 10)
  end

  defp migrate(stats = %{health: health, max_health: max_health}) do
    stats
    |> Map.put(:health_points, health)
    |> Map.put(:max_health_points, max_health)
    |> Map.delete(:health)
    |> Map.delete(:max_health)
  end

  defp migrate(stats), do: stats

  @doc """
  Slots on a character
  """
  @spec slots() :: [atom]
  def slots(),
    do: [
      :chest,
      :head,
      :shoulders,
      :neck,
      :back,
      :hands,
      :waist,
      :legs,
      :feet,
      :leftfinger,
      :rightfinger,
      :goggles
    ]

  @doc """
  Fields in the statistics map
  """
  @spec basic_fields() :: [atom]
  def basic_fields(),
    do: [
      :agility,
      :awareness,
      :intelligence,
      :strength,
      :vitality,
      :willpower
    ]

  @doc """
  Fields in the statistics map
  """
  @spec fields() :: [atom]
  def fields(),
    do: [
      :agility,
      :awareness,
      :endurance_points,
      :health_points,
      :intelligence,
      :max_endurance_points,
      :max_health_points,
      :max_skill_points,
      :skill_points,
      :strength,
      :vitality,
      :willpower
    ]

  @doc """
  Validate a character's stats

      iex> Data.Stats.valid_character?(%{health_points: 50, strength: 10})
      false

      iex> Data.Stats.valid_character?(%{})
      false
  """
  @spec valid_character?(Stats.character()) :: boolean()
  def valid_character?(stats) do
    keys(stats) == fields() && _integer_fields(stats)
  end

  def _integer_fields(stats) do
    Enum.all?(fields(), fn field ->
      is_integer(Map.get(stats, field))
    end)
  end

  @doc """
  Validate an armor item

      iex> Data.Stats.valid_armor?(%{slot: :chest, armor: 10})
      true

      iex> Data.Stats.valid_armor?(%{slot: :chest, armor: :none})
      false

      iex> Data.Stats.valid_armor?(%{slot: :eye, armor: 10})
      false

      iex> Data.Stats.valid_armor?(%{})
      false
  """
  @spec valid_armor?(Stats.armor()) :: boolean()
  def valid_armor?(stats) do
    keys(stats) == [:armor, :slot] && valid_slot?(stats) && is_integer(stats.armor)
  end

  @doc """
  Validate a weapon item

      iex> Data.Stats.valid_weapon?(%{})
      true

      iex> Data.Stats.valid_weapon?(%{anything: true})
      false
  """
  @spec valid_weapon?(Stats.weapon()) :: boolean()
  def valid_weapon?(stats) do
    keys(stats) == []
  end

  @doc """
  Validate an item stats based on type

      iex> Data.Stats.valid?("basic", %{})
      true
      iex> Data.Stats.valid?("basic", %{slot: :chest})
      false
  """
  @spec valid?(String.t(), Stats.t()) :: boolean()
  def valid?(type, stats)

  def valid?("armor", stats) do
    valid_armor?(stats)
  end

  def valid?("weapon", stats) do
    valid_weapon?(stats)
  end

  def valid?("basic", stats) do
    keys(stats) == []
  end

  def valid?(_, _), do: false

  @doc """
  Validate if the slot is right

      iex> Data.Stats.valid_slot?(%{slot: :chest})
      true
      iex> Data.Stats.valid_slot?(%{slot: :eye})
      false
  """
  @spec valid_slot?(Stats.t()) :: boolean()
  def valid_slot?(stats)

  def valid_slot?(%{slot: slot}) do
    slot in slots()
  end
end
