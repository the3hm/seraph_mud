defmodule Game.Command.ListenTest do
  use ExVenture.CommandCase

  alias Game.Command.Listen

  doctest Listen

  @room Test.Game.Room

  setup do
    save = base_save()
    %{state: %{socket: :socket, user: %{save: save}, save: save}}
  end

  describe "listening to the current room" do
    setup do
      room = %{
        listen: "Sounds of water trickling can be heard",
        features: [
          %{key: "flag", listen: "A flag is flapping in the breeze"},
        ],
        npcs: [
          %{name: "Guard", extra: %{status_listen: "[name] is yelling."}},
        ],
      }
      @room.set_room(Map.merge(@room._room(), room))

      :ok
    end

    test "room contains no listening text", %{state: state} do
      @room.set_room(@room._room())

      :ok = Listen.run({}, state)

      assert_socket_echo "nothing can be heard"
    end

    test "includes the room listen text", %{state: state} do
      :ok = Listen.run({}, state)

      assert_socket_echo "trickling"
    end

    test "includes the room's features", %{state: state} do
      :ok = Listen.run({}, state)

      assert_socket_echo "flapping"
    end

    test "includes the room's npcs", %{state: state} do
      :ok = Listen.run({}, state)

      assert_socket_echo ["guard", "yelling"]
    end
  end

  describe "listening in a direction" do
    setup do
      room = %{id: 1, exits: [%{direction: "north", start_id: 1, finish_id: 2}]}
      @room.set_room(Map.merge(@room._room(), room), multiple: true)

      room = %{
        id: 2,
        listen: "Sounds of water trickling can be heard",
        features: [
          %{key: "flag", listen: "A flag is flapping in the breeze"},
        ],
      }
      @room.set_room(Map.merge(@room._room(), room), multiple: true)

      :ok
    end

    test "includes the room listen text", %{state: state} do
      :ok = Listen.run({"north"}, state)

      assert_socket_echo "trickling"
    end

    test "nothing in specified direction", %{state: state} do
      :ok = Listen.run({"south"}, state)

      assert_socket_echo "no exit"
    end
  end
end
