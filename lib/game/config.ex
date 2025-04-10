defmodule Game.Config do
  @moduledoc """
  Hold Config to not query as often
  """

  use GenServer

  alias Data.Config
  alias Data.Repo
  alias Data.Save
  alias Data.Stats

  @networking Application.compile_env(:ex_venture, :networking, %{})

  @color_config %{
    color_home_header: "#268bd2",
    color_home_link: "#268bd2",
    color_home_link_hover: "#31b5ff",
    color_home_primary: "#268bd2",
    color_home_primary_hover: "#2a99e7",
    color_home_primary_text: "#fff",
    color_home_secondary: "#fdf6e3",
    color_home_secondary_hover: "#fcf1d5",
    color_home_secondary_text: "#657b83",
    color_background: "#002b36",
    color_text_color: "#93a1a1",
    color_panel_border: "#073642",
    color_prompt_background: "#fdf6e3",
    color_prompt_color: "#586e75",
    color_character_info_background: "#073642",
    color_character_info_text: "#93a1a1",
    color_room_info_background: "#073642",
    color_room_info_text: "#93a1a1",
    color_room_info_exit: "#93a1a1",
    color_stat_block_background: "#eee8d5",
    color_health_bar: "#dc322f",
    color_health_bar_background: "#fdf6e3",
    color_skill_bar: "#859900",
    color_skill_bar_background: "#fdf6e3",
    color_endurance_bar: "#268bd2",
    color_endurance_bar_background: "#fdf6e3",
    color_experience_bar: "#6c71c4",
    color_black: "#003541",
    color_red: "#dc322f",
    color_green: "#859900",
    color_yellow: "#b58900",
    color_blue: "#268bd2",
    color_magenta: "#d33682",
    color_cyan: "#2aa198",
    color_white: "#eee8d5",
    color_brown: "#875f00",
    color_dark_green: "#005f00",
    color_grey: "#7e9693",
    color_light_grey: "#b6c6c6"
  }

  @basic_stats %{
    health_points: 50,
    max_health_points: 50,
    skill_points: 50,
    max_skill_points: 50,
    endurance_points: 20,
    max_endurance_points: 20,
    strength: 10,
    agility: 10,
    intelligence: 10,
    awareness: 10,
    vitality: 10,
    willpower: 10
  }

  @doc false
  def color_config(), do: @color_config

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @doc """
  Reload a config from the database
  """
  def reload(name) do
    GenServer.call(__MODULE__, {:reload, name})
  end

  @doc false
  def reload(name, value) do
    GenServer.call(__MODULE__, {:reload, name, value})
  end

  @doc """
  Load config from the ets table or refresh from the database
  """
  def find_config(name) do
    case :ets.lookup(__MODULE__, name) do
      [{_, value}] ->
        value

      _ ->
        reload(name)
    end
  end

  @doc false
  def reset() do
    GenServer.call(__MODULE__, :reset)
  end

  def host(), do: ExVenture.config(@networking[:host])
  def port(), do: ExVenture.config(@networking[:port])
  def ssl?(), do: ssl_port() != nil
  def ssl_port(), do: ExVenture.config(@networking[:ssl_port])

  @doc """
  Number of "ticks" before regeneration occurs
  """
  @spec regen_tick_count(Integer.t()) :: Integer.t()
  def regen_tick_count(default) do
    case find_config("regen_tick_count") do
      nil ->
        default

      regen_tick_count ->
        regen_tick_count |> Integer.parse() |> elem(0)
    end
  end

  @doc """
  The Game's name

  Used in web page titles
  """
  def game_name(default \\ "ExVenture") do
    case find_config("game_name") do
      nil ->
        default

      game_name ->
        game_name
    end
  end

  @doc """
  Get the game's description
  """
  def description(default \\ "A MUD built with ExVenture.") do
    case find_config("description") do
      nil ->
        default

      description ->
        description
    end
  end

  @doc """
  The Game's short name

  Used in the web manifest file
  """
  @spec game_short_name(String.t()) :: String.t()
  def game_short_name(default \\ "ExVenture") do
    case find_config("game_short_name") do
      nil ->
        default

      game_short_name ->
        game_short_name
    end
  end

  @doc """
  Message of the Day

  Used during sign in
  """
  @spec motd(String.t()) :: String.t()
  def motd(default \\ "Welcome to ExVenture") do
    case find_config("motd") do
      nil ->
        default

      motd ->
        motd
    end
  end

  @doc """
  Message after signing into the game

  Used during sign in
  """
  @spec after_sign_in_message(String.t()) :: String.t()
  def after_sign_in_message(default \\ "") do
    case find_config("after_sign_in_message") do
      nil ->
        default

      motd ->
        motd
    end
  end

  @doc """
  Starting save

  Which room, etc the player will start out with
  """
  @spec starting_save() :: map()
  def starting_save() do
    case find_config("starting_save") do
      nil ->
        nil

      save ->
        {:ok, save} = Save.load(Poison.decode!(save))
        save
    end
  end

  def starting_room_ids() do
    case find_config("starting_room_ids") do
      nil ->
        []

      room_ids ->
        Poison.decode!(room_ids)
    end
  end

  def starting_room_id() do
    starting_room_ids()
    |> Enum.shuffle()
    |> List.first()
  end

  @doc """
  Your pool of random character names to offer to players signing up
  """
  @spec character_names() :: [String.t()]
  def character_names() do
    case find_config("character_names") do
      nil ->
        []

      names ->
        names
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
    end
  end

  @doc """
  Pick a random set of 5 names
  """
  @spec random_character_names() :: [String.t()]
  def random_character_names() do
    character_names()
    |> Enum.shuffle()
    |> Enum.take(5)
  end

  @doc """
  Remove a name from the list of character names if it was used
  """
  @spec claim_character_name(String.t()) :: :ok
  def claim_character_name(name) do
    case name in character_names() do
      true ->
        _claim_character_name(name)

      false ->
        :ok
    end
  end

  defp _claim_character_name(name) do
    case Repo.get_by(Config, name: "character_names") do
      nil ->
        :ok

      config ->
        names = List.delete(character_names(), name)
        changeset = config |> Config.changeset(%{value: Enum.join(names, "\n")})
        Repo.update(changeset)
        reload("character_names")
    end
  end

  @doc """
  Load the game's basic stats
  """
  @spec basic_stats() :: map()
  def basic_stats() do
    case find_config("basic_stats") do
      nil ->
        @basic_stats

      stats ->
        {:ok, stats} = Stats.load(Poison.decode!(stats))
        stats
    end
  end

  def discord_client_id() do
    find_config("discord_client_id")
  end

  def discord_invite_url() do
    find_config("discord_invite_url")
  end

  def grapevine_only_login?() do
    case find_config("grapevine_only_login") do
      nil ->
        false

      "false" ->
        false

      "true" ->
        true
    end
  end

  Enum.each(@color_config, fn {config, default} ->
    def unquote(config)() do
      case find_config(to_string(unquote(config))) do
        nil ->
          unquote(default)

        color ->
          color
      end
    end
  end)

  def init(_) do
    create_table()
    {:ok, %{}}
  end

  def handle_call({:reload, name}, _from, state) do
    value = Config.find_config(name)
    :ets.insert(__MODULE__, {name, value})
    {:reply, value, state}
  end

  def handle_call({:reload, name, value}, _from, state) do
    :ets.insert(__MODULE__, {name, value})
    {:reply, value, state}
  end

  def handle_call(:reset, _from, state) do
    :ets.delete(__MODULE__)
    create_table()
    {:reply, :ok, state}
  end

  defp create_table() do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
  end
end
