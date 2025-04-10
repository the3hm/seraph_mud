defmodule Game.Command.Examine do
  @moduledoc """
  The "info" command
  """

  use Game.Command

  alias Game.Format.Items, as: FormatItems
  alias Game.Item
  alias Game.Items

  commands(["examine"])

  @impl Game.Command
  def help(:topic), do: "Examine"
  def help(:short), do: "View information about items in your inventory"

  def help(:full) do
    """
    #{help(:short)}

    Example:
    [ ] > {command}examine short sword{/command}
    """
  end

  @impl Game.Command
  @doc """
  View information about items in your inventory
  """
  def run(command, state)

  def run({item_name}, state) do
    %{wearing: wearing, wielding: wielding, items: items} = state.save

    wearing_instances = Enum.map(wearing, &elem(&1, 1))
    wielding_instances = Enum.map(wielding, &elem(&1, 1))

    items = Items.items(wearing_instances ++ wielding_instances ++ items)

    case Item.find_item(items, item_name) do
      {:error, :not_found} ->
        message = "\"#{item_name}\" could not be found."
        state |> Socket.echo(message)

      {:ok, item} ->
        state |> Socket.echo(FormatItems.item(item))
    end
  end

  def run({}, state) do
    message =
      "You don't know what to examine. See {command}help examine{/command} for more information."

    state |> Socket.echo(message)
  end
end
