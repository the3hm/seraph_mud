defmodule Web.JSONHelper do
  @moduledoc """
  Helper functions for displaying stats
  """

  import Phoenix.HTML, only: [raw: 1]

  @doc """
  Encode a map as pretty-printed JSON (HTML safe)
  """
  @spec encode_json(map) :: String.t()
  def encode_json(map) do
    map
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
    |> raw()
  end

  @doc """
  Get a field from a changeset and display as pretty JSON
  """
  @spec json_field(Ecto.Changeset.t(), atom) :: String.t()
  def json_field(changeset, field) do
    case changeset do
      %{changes: %{^field => value}} -> parse_value(value)
      %{data: %{^field => value}} -> parse_value(value)
      %{^field => value} -> parse_value(value)
      _ -> ""
    end
  end

  defp parse_value(nil), do: ""

  defp parse_value(value) do
    with {:ok, encoded} <- Jason.encode(value) do
      Jason.Formatter.pretty_print(encoded)
    else
      _ -> ""
    end
  end
end
