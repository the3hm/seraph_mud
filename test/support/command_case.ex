defmodule ExVenture.CommandCase do
  defmacro __using__(_) do
    quote do
      use Data.ModelCase

      import Test.Networking.Socket.Helpers
      import Test.Game.Room.Helpers
    end
  end
end
