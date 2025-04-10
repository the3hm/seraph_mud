defmodule Data.Weather do
  @moduledoc """
  Weather schema
  """

  use Data.Schema

  schema "weathers" do
    field(:key, :string)
    field(:short_description, :string)
    field(:description, :string)
    field(:listen, :string)
    field(:tags, {:array, :string}, default: [])

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:key, :short_description, :description, :listen, :tags])
    |> validate_required([:key, :short_description, :description, :tags])
  end
end
