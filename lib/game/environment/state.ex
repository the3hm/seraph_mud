defmodule Game.Environment.State do
  @moduledoc """
  Environment state around the player.

  The room's name, description, who else is in the room with the player, etc
  """

  defmodule Room do
    @moduledoc false

    defstruct [
      :id,
      :zone_id,
      :zone,
      :name,
      :description,
      :currency,
      :items,
      :listen,
      :x,
      :y,
      :map_layer,
      :ecology,
      :shops,
      :exits,
      players: [],
      npcs: [],
      features: [],
      weathers: []
    ]
  end

  defmodule Overworld do
    @moduledoc false

    defstruct [
      :id,
      :zone_id,
      :zone,
      :x,
      :y,
      :ecology,
      :exits,
      players: [],
      npcs: []
    ]
  end
end
