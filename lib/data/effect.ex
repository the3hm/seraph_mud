defmodule Data.Effect do
  @moduledoc """
  In game effects such as damage

  Valid kinds of effects:

  - "damage": Does an amount of damage
  - "damage/type": Halves damage if the type does not align
  - "damage/over-time": Does damage over time
  - "recover/over-time": heals an amount over time
  - "recover": Heals an amount of health/skill/move points
  - "stats": Modify base stats for the player
  - "room/state": Modify the state of the room of the user
  """

  import Data.Type
  import Ecto.Changeset

  alias Data.Effect
  alias Data.Stats

  @modes ["add", "multiply", "subtract", "divide"]

  @type t :: map

  @type damage :: %{
          type: String.t(),
          amount: integer
        }

  @type damage_type :: %{
          types: [String.t()]
        }

  @typedoc """
  Damage over time. Does damage every `every` milliseconds.
  """
  @type damage_over_time :: %{
          type: String.t(),
          amount: integer(),
          every: integer(),
          count: integer()
        }

  @type recover_over_time :: %{
          type: atom(),
          amount: integer(),
          every: integer(),
          count: integer()
        }

  @type heal :: %{
          amount: integer
        }

  @type recover :: %{
          type: atom(),
          amount: integer()
        }

  @type stats :: %{
          field: atom,
          mode: String.t(),
          amount: integer
        }

  @type stats_boost :: %{
          field: atom(),
          amount: integer(),
          mode: String.t(),
          duration: integer()
        }

  @behaviour Ecto.Type

  @doc """
  A list of all types in the system.
  """
  def types() do
    [
      "damage",
      "damage/over-time",
      "damage/type",
      "recover/over-time",
      "recover",
      "stats",
      "stats/boost",
      "room/state"
    ]
  end

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(stats) when is_map(stats), do: {:ok, stats}
  def cast(_), do: :error

  @doc """
  Load an effect from a stored map

  Cast it properly

      iex> Data.Effect.load(%{"kind" => "damage", "type" => "slashing", "amount" => 10})
      {:ok, %{kind: "damage", type: "slashing", amount: 10}}

      iex> Data.Effect.load(%{"kind" => "damage/type", "types" => ["slashing"]})
      {:ok, %{kind: "damage/type", types: ["slashing"]}}

      iex> Data.Effect.load(%{"kind" => "damage/over-time", "type" => "slashing", "amount" => 10, "every" => 3})
      {:ok, %{kind: "damage/over-time", type: "slashing", amount: 10, every: 3}}

      iex> Data.Effect.load(%{"kind" => "stats", "field" => "agility"})
      {:ok, %{kind: "stats", field: :agility, mode: "add"}}
  """
  @impl Ecto.Type
  def load(effect) do
    effect = for {key, val} <- effect, into: %{}, do: {String.to_atom(key), val}
    effect = effect.kind |> cast_vals(effect)
    {:ok, effect}
  end

  defp cast_vals("heal", effect) do
    effect |> Map.put(:type, String.to_atom(effect.type))
  end

  defp cast_vals("stats", effect) do
    effect
    |> Map.put(:field, String.to_atom(effect.field))
    |> ensure(:mode, "add")
  end

  defp cast_vals("stats/boost", effect) do
    effect |> Map.put(:field, String.to_atom(effect.field))
  end

  defp cast_vals(_type, effect), do: effect

  @impl Ecto.Type
  def dump(stats) when is_map(stats), do: {:ok, Map.delete(stats, :__struct__)}
  def dump(_), do: :error

  @impl true
  def embed_as(_), do: :self

  @impl true
  def equal?(term1, term2), do: term1 == term2

  @doc """
  Get a starting effect, to fill out in the web interface. Just the structure,
  the values won't mean anyhting.
  """
  @spec starting_effect(String.t()) :: t()
  def starting_effect("damage") do
    %{kind: "damage", type: "slashing", amount: 0}
  end

  def starting_effect("damage/type") do
    %{kind: "damage/type", types: []}
  end

  def starting_effect("damage/over-time") do
    %{kind: "damage/over-time", type: "slashing", amount: 0, every: 10, count: 2}
  end

  def starting_effect("recover/over-time") do
    %{kind: "recover/over-time", type: "health", amount: 0, every: 10, count: 2}
  end

  def starting_effect("recover") do
    %{kind: "recover", type: "health", amount: 0}
  end

  def starting_effect("stats") do
    %{kind: "stats", field: :agility, amount: 0}
  end

  def starting_effect("stats/boost") do
    %{kind: "stats/boost", field: :agility, amount: 0, duration: 1000, mode: "add"}
  end

  @doc """
  Validate an effect based on type

      iex> Data.Effect.valid?(%{kind: "damage", type: "slashing", amount: 10})
      true
      iex> Data.Effect.valid?(%{kind: "damage", type: "slashing", amount: :invalid})
      false

      iex> Data.Effect.valid?(%{kind: "damage/type", types: ["slashing"]})
      true

      iex> Data.Effect.valid?(%{kind: "damage/over-time", type: "slashing", amount: 10, every: 3, count: 3})
      true
      iex> Data.Effect.valid?(%{kind: "damage/over-time", type: "something", amount: :hi, every: 3, count: 3})
      false

      iex> Data.Effect.valid?(%{kind: "recover", type: "skill", amount: 10})
      true
      iex> Data.Effect.valid?(%{kind: "recover", type: "skill", amount: :invalid})
      false

      iex> Data.Effect.valid?(%{kind: "stats", field: :strength, amount: 10, mode: "add"})
      true
      iex> Data.Effect.valid?(%{kind: "stats", field: :strength, amount: :invalid})
      false
  """
  @spec valid?(Stats.t()) :: boolean
  def valid?(effect)

  def valid?(effect = %{kind: "damage"}) do
    keys(effect) == [:amount, :kind, :type] && valid_damage?(effect)
  end

  def valid?(effect = %{kind: "damage/type"}) do
    keys(effect) == [:kind, :types] && valid_damage_type?(effect)
  end

  def valid?(effect = %{kind: "damage/over-time"}) do
    keys(effect) == [:amount, :count, :every, :kind, :type] && valid_damage_over_time?(effect)
  end

  def valid?(effect = %{kind: "recover/over-time"}) do
    keys(effect) == [:amount, :count, :every, :kind, :type] && valid_recover_over_time?(effect)
  end

  def valid?(effect = %{kind: "recover"}) do
    keys(effect) == [:amount, :kind, :type] && valid_recover?(effect)
  end

  def valid?(effect = %{kind: "stats"}) do
    keys(effect) == [:amount, :field, :kind, :mode] && valid_stats?(effect)
  end

  def valid?(effect = %{kind: "stats/boost"}) do
    keys(effect) == [:amount, :duration, :field, :kind, :mode] && valid_stats_boost?(effect)
  end

  def valid?(_), do: false

  @doc """
  Validate if damage is right

      iex> Data.Effect.valid_damage?(%{type: "slashing", amount: 10})
      true

      iex> Data.Effect.valid_damage?(%{type: "slashing", amount: nil})
      false

      iex> Data.Effect.valid_damage?(%{type: "finger"})
      false
  """
  @spec valid_damage?(Effect.t()) :: boolean
  def valid_damage?(effect)

  def valid_damage?(%{type: type, amount: amount}) do
    is_binary(type) && is_integer(amount)
  end

  def valid_damage?(_), do: false

  @doc """
  Validate if damage/type is right

      iex> Data.Effect.valid_damage_type?(%{types: ["slashing"]})
      true

      iex> Data.Effect.valid_damage_type?(%{types: :slashing})
      false
  """
  @spec valid_damage_type?(Effect.t()) :: boolean
  def valid_damage_type?(effect)

  def valid_damage_type?(%{types: types}) when is_list(types) do
    Enum.all?(types, &is_binary(&1))
  end

  def valid_damage_type?(_), do: false

  @doc """
  Validate if `damage/over-time` is right

      iex> Data.Effect.valid_damage_over_time?(%{type: "slashing", amount: 10, every: 3, count: 3})
      true

      iex> Data.Effect.valid_damage_over_time?(%{type: "slashing", amount: :ten, every: 3, count: 3})
      false

      iex> Data.Effect.valid_damage_over_time?(%{type: "slashing", amount: 10, every: :three, count: 3})
      false

      iex> Data.Effect.valid_damage_over_time?(%{type: "slashing", amount: 10, every: 3, count: :three})
      false
  """
  @spec valid_damage_over_time?(Effect.t()) :: boolean
  def valid_damage_over_time?(effect)

  def valid_damage_over_time?(%{type: type, amount: amount, every: every, count: count}) do
    is_binary(type) && is_integer(amount) && is_integer(every) && every > 0 && is_integer(count) &&
      count > 0
  end

  def valid_damage_over_time?(_), do: false

  @spec valid_recover_over_time?(Effect.t()) :: boolean
  def valid_recover_over_time?(effect)

  def valid_recover_over_time?(%{type: type, amount: amount, every: every, count: count}) do
    is_binary(type) && is_integer(amount) && is_integer(every) && every > 0 && is_integer(count) &&
      count > 0
  end

  def valid_recover_over_time?(_), do: false

  @doc """
  Validate if recover is right

      iex> Data.Effect.valid_recover?(%{type: "health", amount: 10})
      true

      iex> Data.Effect.valid_recover?(%{type: "skill", amount: 10})
      true

      iex> Data.Effect.valid_recover?(%{type: "move", amount: 10})
      true

      iex> Data.Effect.valid_recover?(%{type: "skill", amount: :invalid})
      false
      iex> Data.Effect.valid_recover?(%{type: "other", amount: 10})
      false
  """
  @spec valid_recover?(Effect.t()) :: boolean
  def valid_recover?(effect)

  def valid_recover?(%{type: type, amount: amount}) do
    type in ["health", "skill", "move"] && is_integer(amount)
  end

  def valid_recover?(_), do: false

  @doc """
  Validate if the stats type is right

      iex> Data.Effect.valid_stats?(%{field: :strength, amount: 10, mode: "add"})
      true

      iex> Data.Effect.valid_stats?(%{field: :strength, amount: nil, mode: "add"})
      false

      iex> Data.Effect.valid_stats?(%{field: :strength, amount: 10, mode: "remove"})
      false

      iex> Data.Effect.valid_stats?(%{field: :head, amount: 10, mode: "add"})
      false

      iex> Data.Effect.valid_stats?(%{field: :strength})
      false
  """
  @spec valid_stats?(Effect.t()) :: boolean
  def valid_stats?(effect)

  def valid_stats?(%{field: field, amount: amount, mode: mode}) do
    field in Stats.fields() && mode in @modes && is_integer(amount)
  end

  def valid_stats?(_), do: false

  @doc """
  Validate if the stats type is right

      iex> Data.Effect.valid_stats_boost?(%{field: :strength, amount: 10, duration: 10, mode: "add"})
      true

      iex> Data.Effect.valid_stats_boost?(%{field: :strength, amount: nil, duration: 10, mode: "add"})
      false

      iex> Data.Effect.valid_stats_boost?(%{field: :strength, amount: 10, duration: nil, mode: "add"})
      false

      iex> Data.Effect.valid_stats_boost?(%{field: :head, amount: 10, duration: 10})
      false

      iex> Data.Effect.valid_stats_boost?(%{field: :strength})
      false
  """
  @spec valid_stats_boost?(Effect.t()) :: boolean
  def valid_stats_boost?(effect)

  def valid_stats_boost?(%{field: field, amount: amount, duration: duration, mode: mode}) do
    field in Stats.fields() && mode in @modes && is_integer(amount) && is_integer(duration)
  end

  def valid_stats_boost?(_), do: false

  def validate_effects(changeset) do
    case changeset do
      %{changes: %{effects: effects}} when effects != nil ->
        _validate_effects(changeset)

      _ ->
        changeset
    end
  end

  defp _validate_effects(changeset = %{changes: %{effects: effects}}) do
    case effects |> Enum.all?(&Effect.valid?/1) do
      true -> changeset
      false -> add_error(changeset, :effects, "are invalid")
    end
  end

  @doc """
  Check if an effect is continuous or not

    iex> Data.Effect.continuous?(%{kind: "damage/over-time"})
    true

    iex> Data.Effect.continuous?(%{kind: "stats/boost"})
    true

    iex> Data.Effect.continuous?(%{kind: "damage"})
    false
  """
  @spec continuous?(Effect.t()) :: boolean()
  def continuous?(effect)
  def continuous?(%{kind: "damage/over-time"}), do: true
  def continuous?(%{kind: "recover/over-time"}), do: true
  def continuous?(%{kind: "stats/boost"}), do: true
  def continuous?(_), do: false

  @doc """
  Check if an effect is continuous and should apply to every effect coming in

    iex> Data.Effect.applies_to_every_effect?(%{kind: "stats/boost"})
    true

    iex> Data.Effect.applies_to_every_effect?(%{kind: "damage/over-time"})
    false

    iex> Data.Effect.continuous?(%{kind: "damage"})
    false
  """
  @spec applies_to_every_effect?(Effect.t()) :: boolean()
  def applies_to_every_effect?(effect)
  def applies_to_every_effect?(%{kind: "stats/boost"}), do: true
  def applies_to_every_effect?(_), do: false

  @doc """
  Instantiate an effect by giving it an ID to track, for future callbacks
  """
  @spec instantiate(Effect.t()) :: boolean()
  def instantiate(effect) do
    effect |> Map.put(:id, UUID.uuid4())
  end
end
