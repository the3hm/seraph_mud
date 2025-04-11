defmodule Web.Admin.BugController do
  @moduledoc """
  Admin controller for viewing and managing player-reported bugs.
  """

  use Web.AdminController

  alias Web.Bug

  plug(Web.Plug.FetchPage when action in [:index])

  @doc """
  Lists all reported bugs with optional filters.
  """
  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "bug", %{})

    %{page: bugs, pagination: pagination} =
      Bug.all(filter: filter, page: page, per: per)

    render(conn, :index,
      bugs: bugs,
      filter: filter,
      pagination: pagination
    )
  end

  @doc """
  Shows details for a single bug report.
  """
  def show(conn, %{"id" => id}) do
    bug = Bug.get(id)
    render(conn, :show, bug: bug)
  end

  @doc """
  Marks a bug as completed.
  """
  def complete(conn, %{"bug_id" => id}) do
    case Bug.complete(id) do
      {:ok, bug} ->
        redirect(conn,
          to: ~p"/admin/bugs/#{bug.id}",
          flash: [info: "Bug marked as completed!"]
        )

      _ ->
        redirect(conn,
          to: ~p"/admin/bugs",
          flash: [error: "There was an issue marking the bug as complete. Please try again."]
        )
    end
  end
end
