defmodule Game.Zone do
  @moduledoc """
  Supervisor for Rooms
  """

  @type t :: %{
          name: String.t()
        }

  use GenServer

  require Logger

  alias Game.Door
  alias Game.Map, as: GameMap
  alias Game.NPC
  alias Game.Overworld
  alias Game.Room
  alias Game.Shop
  alias Game.World.Master, as: WorldMaster
  alias Game.Zone.Repo, as: ZoneRepo

  @key :zones

  @zone Keyword.get(Application.compile_env(:ex_venture, :game, []), :zone)

  defmacro __using__(_opts) do
    quote do
      @zone Keyword.get(Application.compile_env(:ex_venture, :game, []), :zone)
    end
  end

  def start_link(zone) do
    GenServer.start_link(__MODULE__, zone, name: pid(zone.id))
  end

  defp pid(id) do
    {:global, {Game.Zone, id}}
  end

  @doc """
  Return all zones
  """
  @spec all() :: [map]
  def all() do
    ZoneRepo.all()
  end

  # Client functions

  @doc """
  Let the zone know a room is online
  """
  def room_online(id, room) do
    GenServer.cast(pid(id), {:room_online, room, self()})
  end

  @doc """
  Let the zone know a npc is online
  """
  def npc_online(id, npc) do
    GenServer.cast(pid(id), {:npc_online, npc, self()})
  end

  @doc """
  Update a zone definition in the server state
  """
  @spec update(integer, Zone.t()) :: :ok
  def update(id, zone) do
    GenServer.cast(pid(id), {:update, zone})
  end

  @doc """
  Tell the zone where the room supervisor lives
  """
  @spec room_supervisor(integer, pid) :: :ok
  def room_supervisor(id, supervisor_pid) do
    GenServer.cast(pid(id), {:room_supervisor, supervisor_pid})
  end

  @doc """
  Tell the zone where the npc supervisor lives
  """
  @spec npc_supervisor(integer, pid) :: :ok
  def npc_supervisor(id, supervisor_pid) do
    GenServer.cast(pid(id), {:npc_supervisor, supervisor_pid})
  end

  @doc """
  Tell the zone where the shop supervisor lives
  """
  @spec shop_supervisor(integer, pid) :: :ok
  def shop_supervisor(id, supervisor_pid) do
    GenServer.cast(pid(id), {:shop_supervisor, supervisor_pid})
  end

  @doc """
  Start a new room in the supervision tree
  """
  @spec spawn_room(integer, Data.Room.t()) :: :ok
  def spawn_room(id, room) do
    GenServer.cast(pid(id), {:spawn_room, room})
  end

  @doc """
  Start a new npc in the supervision tree
  """
  @spec spawn_npc(integer, Data.NPCSpawner.t()) :: :ok
  def spawn_npc(id, npc_spawner) do
    GenServer.cast(pid(id), {:spawn_npc, npc_spawner})
  end

  @doc """
  Start a new shop in the supervision tree
  """
  @spec spawn_shop(integer, Data.Shop.t()) :: :ok
  def spawn_shop(id, shop) do
    GenServer.cast(pid(id), {:spawn_shop, shop})
  end

  @doc """
  Update a room's definition in the state
  """
  @spec update_room(integer, Room.t()) :: :ok
  def update_room(id, room) do
    GenServer.cast(pid(id), {:update_room, room, self()})
  end

  @doc """
  Display a map of the zone
  """
  @spec map(integer, {integer, integer}, Keyword.t()) :: String.t()
  def map(id, player_at, opts \\ []) do
    GenServer.call(pid(id), {:map, player_at, opts})
  end

  @doc """
  Get a simple version of the zone
  """
  def name(id) do
    case Cachex.get(@key, id) do
      {:ok, zone} when zone != nil -> {:ok, zone}
      _ ->
        case ZoneRepo.get_name(id) do
          {:ok, zone} ->
            Cachex.put(@key, zone.id, zone)
            {:ok, zone}

          {:error, :unknown} -> {:error, :unknown}
        end
    end
  end

  @doc """
  Get the graveyard for a zone
  """
  def graveyard(id) do
    GenServer.call(pid(id), :graveyard)
  end

  @doc """
  Terminate a room process
  """
  def terminate_room(room) do
    GenServer.call(pid(room.zone_id), {:terminate, :room, room.id})
  end

  @doc """
  Crash a zone process with an unmatched cast
  """
  def crash(id) do
    GenServer.cast(pid(id), :crash)
  end

  @doc """
  For testing purposes, get the server's state
  """
  def _get_state(id) do
    GenServer.call(pid(id), :get_state)
  end

  # Server callbacks

  def init(zone) do
    Process.flag(:trap_exit, true)

    state = %{
      zone_id: zone.id,
      zone: nil,
      rooms: [],
      room_pids: [],
      room_supervisor_pid: nil,
      npcs: [],
      npc_pids: [],
      npc_supervisor_pid: nil,
      shop_supervisor_pid: nil
    }

    {:ok, state, {:continue, :load_zone}}
  end

  def handle_continue(:load_zone, state) do
    zone = ZoneRepo.get(state.zone_id)
    WorldMaster.update_cache(@key, zone)
    {:noreply, %{state | zone: zone}}
  end

  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  def handle_call(:graveyard, _from, state) do
    case state.zone do
      %{graveyard_id: graveyard_id} when graveyard_id != nil -> {:reply, {:ok, graveyard_id}, state}
      _ -> {:reply, {:error, :no_graveyard}, state}
    end
  end

  def handle_call({:map, player_at, opts}, _from, %{zone: %{type: "rooms"} = zone} = state) do
    map = """
    #{zone.name}

    #{GameMap.display_map(state, player_at, opts)}
    """
    {:reply, String.trim(map), state}
  end

  def handle_call({:map, {x, y}, _opts}, _from, %{zone: %{type: "overworld"} = zone} = state) do
    cell = %{x: x, y: y}
    map = """
    #{zone.name}

    #{Overworld.map(zone, cell)}
    """
    {:reply, String.trim(map), state}
  end

  def handle_call({:terminate, :room, room_id}, _from, state) do
    Supervisor.terminate_child(state.room_supervisor_pid, room_id)
    {:reply, :ok, state}
  end

  def handle_cast({:room_online, room, room_pid}, state) do
    Process.link(room_pid)
    Enum.each(room.exits, &Door.maybe_load/1)
    {:noreply, update_room_state(state, room, room_pid)}
  end

  def handle_cast({:npc_online, npc, npc_pid}, state) do
    Process.link(npc_pid)
    {:noreply, update_npc_state(state, npc, npc_pid)}
  end

  def handle_cast({:update, zone}, state) do
    WorldMaster.update_cache(@key, zone)
    {:noreply, Map.put(state, :zone, zone)}
  end

  def handle_cast({:room_supervisor, pid}, state), do: {:noreply, Map.put(state, :room_supervisor_pid, pid)}
  def handle_cast({:npc_supervisor, pid}, state), do: {:noreply, Map.put(state, :npc_supervisor_pid, pid)}
  def handle_cast({:shop_supervisor, pid}, state), do: {:noreply, Map.put(state, :shop_supervisor_pid, pid)}

  def handle_cast({:spawn_room, room}, %{room_supervisor_pid: pid} = state) do
    Room.Supervisor.start_child(pid, room)
    Room.Supervisor.start_bus(pid, room)
    {:noreply, state}
  end

  def handle_cast({:spawn_npc, npc_spawner}, %{npc_supervisor_pid: pid} = state) do
    NPC.Supervisor.start_child(pid, npc_spawner)
    {:noreply, state}
  end

  def handle_cast({:spawn_shop, shop}, %{shop_supervisor_pid: pid} = state) do
    Shop.Supervisor.start_child(pid, shop)
    {:noreply, state}
  end

  def handle_cast({:update_room, new_room, room_pid}, state) do
    rooms = Enum.reject(state.rooms, &(&1.id == new_room.id))
    room_pids = Enum.reject(state.room_pids, fn {pid, _} -> pid == room_pid end)
    {:noreply, %{state | rooms: [new_room | rooms], room_pids: [{room_pid, new_room.id} | room_pids]}}
  end

  def handle_info({:EXIT, pid, _reason}, state) do
    {rooms, room_pids} = reject_room_by_pid(state, pid)
    {npcs, npc_pids} = reject_npc_by_pid(state, pid)
    {:noreply, %{state | rooms: rooms, room_pids: room_pids, npcs: npcs, npc_pids: npc_pids}}
  end

  defp update_room_state(state, room, room_pid) do
    %{state | rooms: [room | state.rooms], room_pids: [{room_pid, room.id} | state.room_pids]}
  end

  defp update_npc_state(state, npc, npc_pid) do
    %{state | npcs: [npc | state.npcs], npc_pids: [{npc_pid, npc.id} | state.npc_pids]}
  end

  defp reject_room_by_pid(state, pid) do
    case find_pid(state.room_pids, pid) do
      {_pid, room_id} ->
        case Enum.find(state.rooms, &(&1.id == room_id)) do
          nil -> {state.rooms, state.room_pids}
          room -> {
            Enum.reject(state.rooms, &(&1.id == room.id)),
            Enum.reject(state.room_pids, &(elem(&1, 0) == pid))
          }
        end

      nil -> {state.rooms, state.room_pids}
    end
  end

  defp reject_npc_by_pid(state, pid) do
    case find_pid(state.npc_pids, pid) do
      {_pid, npc_id} ->
        case Enum.find(state.npcs, &(&1.id == npc_id)) do
          nil -> {state.npcs, state.npc_pids}
          npc -> {
            Enum.reject(state.npcs, &(&1.id == npc.id)),
            Enum.reject(state.npc_pids, &(elem(&1, 0) == pid))
          }
        end

      nil -> {state.npcs, state.npc_pids}
    end
  end

  defp find_pid(pids, matching_pid), do: Enum.find(pids, fn {pid, _} -> pid == matching_pid end)
end
