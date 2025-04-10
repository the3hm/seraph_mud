defmodule Web.Admin.NPCEventView do
  @moduledoc """
  View helpers for rendering NPC events
  """

  use Web, :view

  alias Data.Events
  alias Web.Admin.SharedView

  def parse(event) do
    case Events.parse(event) do
      {:ok, parsed_event} ->
        content_tag(:pre) do
          parsed_event
          |> Jason.encode!()
          |> Jason.Formatter.pretty_print()
        end

      {:error, error} ->
        error_msg = content_tag(:code, inspect(error))

        fallback_json =
          event
          |> Jason.encode!()
          |> Jason.Formatter.pretty_print()
          |> content_tag(:pre)

        [
          "Error parsing the event: ",
          error_msg,
          ". Showing the underlying data instead.",
          fallback_json
        ]
    end
  end
end
