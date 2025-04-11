defmodule Web.RaceController do
  @moduledoc """
  Displays the list of races and individual race details.
  """

  use Web, :controller

  alias Web.Race

  def index(conn, _params) do
    races = Race.all(alpha: true)
    render(conn, :index, races: races)
  end

  def show(conn, %{"id" => id}) do
    case Race.get(id) do
      nil ->
        redirect(conn, to: ~p"/")

      race ->
        render(conn, :show, race: race, extended: true)
    end
  end
end
