defmodule Game.Effect do
  @moduledoc """
  Calculate and apply effects from skills/items
  """

  alias Data.Effect
  alias Data.Stats
  alias Game.DamageTypes

  @random_effect_range Application.compile_env(:ex_venture, :game, [])[:random_effect_range]

  @type continuous_effect :: {Character.t(), Effec.t()}

  @doc """
  Calculate effects based on the user

  Filters out stat boosting effects, then deals with damage & recovery
  """
  @spec calculate(Stats.t(), [Effect.t()]) :: [map()]
  def calculate(stats, effects) do
    {stats, effects} = stats |> calculate_stats(effects)
    {stats_boost, effects} = effects |> Enum.split_with(&(&1.kind == "stats/boost"))

    {damage_effects, effects} = effects |> Enum.split_with(&(&1.kind == "damage"))
    damage = damage_effects |> Enum.map(&calculate_damage(&1, stats))

    {damage_over_time_effects, effects} =
      effects |> Enum.split_with(&(&1.kind == "damage/over-time"))

    damage_over_time = damage_over_time_effects |> Enum.map(&calculate_damage(&1, stats))

    {recover_over_time_effects, effects} =
      effects |> Enum.split_with(&(&1.kind == "recover/over-time"))

    recover_over_time = recover_over_time_effects |> Enum.map(&calculate_recover(&1, stats))

    {recover_effects, effects} = effects |> Enum.split_with(&(&1.kind == "recover"))
    recover = recover_effects |> Enum.map(&calculate_recover(&1, stats))

    {damage_type_effects, _effects} = effects |> Enum.split_with(&(&1.kind == "damage/type"))
    damage = damage_type_effects |> Enum.reduce(damage, &calculate_damage_type/2)

    stats_boost ++ damage ++ damage_over_time ++ recover_over_time ++ recover
  end

  @doc """
  Calculate stats and return any effects that were not processed

    iex> stats = %{strength: 10}
    iex> effects = [%{kind: "stats", mode: "add", field: :strength, amount: 10}, %{kind: "damage"}]
    iex> Game.Effect.calculate_stats(stats, effects)
    {%{strength: 20}, [%{kind: "damage"}]}
  """
  @spec calculate_stats(Stats.t(), [Effect.t()]) :: Stats.t()
  def calculate_stats(stats, effects) do
    {stat_effects, effects} = effects |> Enum.split_with(&(&1.kind == "stats"))
    stats = Enum.reduce(stat_effects, stats, &process_stats/2)
    {stats, effects}
  end

  @doc """
  Calculate a character's stats based on the current continuous effects on them
  """
  @spec calculate_stats_from_continuous_effects(Stats.t(), map()) :: [Effect.t()]
  def calculate_stats_from_continuous_effects(stats, state) do
    state.continuous_effects
    |> Enum.map(&elem(&1, 1))
    |> Enum.filter(&(&1.kind == "stats/boost"))
    |> Enum.reduce(stats, &process_stats/2)
  end

  @doc """
  Process stats effects

      iex> Game.Effect.process_stats(%{field: :strength, mode: "add", amount: 10}, %{strength: 10})
      %{strength: 20}
  """
  @spec process_stats(Effect.t(), Stats.t()) :: Stats.t()
  def process_stats(effect, stats)

  def process_stats(effect, stats) do
    case effect.mode do
      "add" ->
        stats |> Map.put(effect.field, stats[effect.field] + effect.amount)

      "subtract" ->
        stats |> Map.put(effect.field, stats[effect.field] - effect.amount)

      "multiply" ->
        stats |> Map.put(effect.field, stats[effect.field] * effect.amount)

      "division" ->
        stats |> Map.put(effect.field, round(stats[effect.field] / effect.amount))
    end
  end

  @doc """
  Calculate damage
  """
  @spec calculate_damage(Effect.t(), Stats.t()) :: map()
  def calculate_damage(effect, stats) do
    case DamageTypes.get(effect.type) do
      {:ok, damage_type} ->
        stat = Map.get(stats, damage_type.stat_modifier)
        random_swing = Enum.random(@random_effect_range)
        modifier = 1 + stat / damage_type.boost_ratio + random_swing / 100
        modified_amount = max(round(Float.ceil(effect.amount * modifier)), 0)
        effect |> Map.put(:amount, modified_amount)

      _ ->
        effect
    end
  end

  @doc """
  Calculate recovery

      iex> effect = %{kind: "recover", type: "health", amount: 10}
      iex> Game.Effect.calculate_recover(effect, %{})
      %{kind: "recover", type: "health", amount: 10}
  """
  @spec calculate_recover(Effect.t(), Stats.t()) :: map()
  def calculate_recover(effect, _stats) do
    random_swing = Enum.random(@random_effect_range)
    modifier = 1 + random_swing / 100
    modified_amount = round(Float.ceil(effect.amount * modifier))

    effect |> Map.put(:amount, modified_amount)
  end

  @doc """
  Calculate damage type effects

  Damage:
      iex> effect = %{kind: "damage/type", types: ["slashing"]}
      iex> damage = %{kind: "damage", amount: 10, type: "bludgeoning"}
      iex> Game.Effect.calculate_damage_type(effect, [damage])
      [%{kind: "damage", amount: 5, type: "bludgeoning"}]
  """
  @spec calculate_damage_type(Effect.t(), Stats.t()) :: map()
  def calculate_damage_type(effect, damages) do
    damages
    |> Enum.map(fn damage ->
      case damage.type in effect.types do
        true ->
          damage

        false ->
          amount = round(Float.ceil(damage.amount / 2.0))
          %{damage | amount: amount}
      end
    end)
  end

  @doc """
  Adjust effects before applying them to a character
  """
  @spec adjust_effects([Effect.t()], Stats.t()) :: [Effect.t()]
  def adjust_effects(effects, stats) do
    effects |> Enum.map(&adjust_effect(&1, stats))
  end

  @doc """
  Adjust a single effect
  """
  @spec adjust_effect(Effect.t(), Stats.t()) :: Effect.t()
  def adjust_effect(effect, stats)

  def adjust_effect(effect = %{kind: "damage"}, stats) do
    case DamageTypes.get(effect.type) do
      {:ok, damage_type} ->
        stat = Map.get(stats, damage_type.reverse_stat)
        random_swing = Enum.random(@random_effect_range)
        modifier = 1 + stat / damage_type.reverse_boost + random_swing / 100
        modified_amount = round(Float.ceil(effect.amount / modifier))

        effect |> Map.put(:amount, modified_amount)

      _ ->
        effect
    end
  end

  def adjust_effect(effect = %{kind: "damage/over-time"}, stats) do
    case DamageTypes.get(effect.type) do
      {:ok, damage_type} ->
        stat = Map.get(stats, damage_type.reverse_stat)
        random_swing = Enum.random(@random_effect_range)
        modifier = 1 + stat / damage_type.reverse_boost + random_swing / 100
        modified_amount = round(Float.ceil(effect.amount / modifier))

        effect |> Map.put(:amount, modified_amount)

      _ ->
        effect
    end
  end

  def adjust_effect(effect, _stats), do: effect

  @doc """
  Apply effects to stats.
  """
  @spec apply([Effect.t()], Stats.t()) :: Stats.t()
  def apply(effects, stats) do
    effects |> Enum.reduce(stats, &apply_effect/2)
  end

  @doc """
  Apply an effect to stats
  """
  @spec apply_effect(Effect.t(), Stats.t()) :: Stats.t()
  def apply_effect(effect, stats)

  def apply_effect(effect = %{kind: "damage"}, stats) do
    %{health_points: health_points} = stats
    Map.put(stats, :health_points, health_points - effect.amount)
  end

  def apply_effect(effect = %{kind: "damage/over-time"}, stats) do
    %{health_points: health_points} = stats
    Map.put(stats, :health_points, health_points - effect.amount)
  end

  def apply_effect(effect = %{kind: "recover/over-time", type: "health"}, stats) do
    %{health_points: health_points, max_health_points: max_health_points} = stats
    health_points = max_recover(health_points, effect.amount, max_health_points)
    %{stats | health_points: health_points}
  end

  def apply_effect(effect = %{kind: "recover/over-time", type: "skill"}, stats) do
    %{skill_points: skill_points, max_skill_points: max_skill_points} = stats
    skill_points = max_recover(skill_points, effect.amount, max_skill_points)
    %{stats | skill_points: skill_points}
  end

  def apply_effect(effect = %{kind: "recover/over-time", type: "endurance"}, stats) do
    %{endurance_points: endurance_points, max_endurance_points: max_endurance_points} = stats
    endurance_points = max_recover(endurance_points, effect.amount, max_endurance_points)
    %{stats | endurance_points: endurance_points}
  end

  def apply_effect(effect = %{kind: "recover", type: "health"}, stats) do
    %{health_points: health_points, max_health_points: max_health_points} = stats
    health_points = max_recover(health_points, effect.amount, max_health_points)
    %{stats | health_points: health_points}
  end

  def apply_effect(effect = %{kind: "recover", type: "skill"}, stats) do
    %{skill_points: skill_points, max_skill_points: max_skill_points} = stats
    skill_points = max_recover(skill_points, effect.amount, max_skill_points)
    %{stats | skill_points: skill_points}
  end

  def apply_effect(effect = %{kind: "recover", type: "endurance"}, stats) do
    %{endurance_points: endurance_points, max_endurance_points: max_endurance_points} = stats
    endurance_points = max_recover(endurance_points, effect.amount, max_endurance_points)
    %{stats | endurance_points: endurance_points}
  end

  def apply_effect(_effect, stats), do: stats

  @doc """
  Limit recovery to the max points

      iex> Game.Effect.max_recover(10, 1, 15)
      11

      iex> Game.Effect.max_recover(10, 6, 15)
      15
  """
  @spec max_recover(integer(), integer(), integer()) :: integer()
  def max_recover(current_points, amount, max_points) do
    case current_points + amount do
      current_points when current_points > max_points -> max_points
      current_points -> current_points
    end
  end

  @doc """
  Filters to continuous effects only

  - `damage/over-time`
  - `recover/over-time`
  """
  @spec continuous_effects([Effect.t()], Character.t()) :: [Effect.t()]
  def continuous_effects(effects, from) do
    effects
    |> Enum.filter(&Effect.continuous?/1)
    |> Enum.map(&Effect.instantiate/1)
    |> Enum.map(fn effect ->
      {from, effect}
    end)
  end

  @doc """
  Start the continuous effect tick cycle if required

  Effect must have an "every" field, such as damage over time
  """
  @spec maybe_tick_effect(Effect.t(), pid()) :: :ok
  def maybe_tick_effect(effect, pid) do
    cond do
      Map.has_key?(effect, :every) ->
        :erlang.send_after(effect.every, pid, {:continuous_effect, effect.id})

      Map.has_key?(effect, :duration) ->
        :erlang.send_after(effect.duration, pid, {:continuous_effect, :clear, effect.id})

      true ->
        :ok
    end
  end

  @doc """
  """
  @spec find_effect(map(), String.t()) :: {:ok, Effect.t()} | {:error, :not_found}
  def find_effect(state, effect_id) do
    effect =
      Enum.find(state.continuous_effects, fn {_from, effect} ->
        effect.id == effect_id
      end)

    case effect do
      nil ->
        {:error, :not_found}

      effect ->
        {:ok, effect}
    end
  end
end
