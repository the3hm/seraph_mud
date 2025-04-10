defmodule Web.RaceController do
  @moduledoc """
  Displays the list of races and individual race details.
  """

  use Web, :controller

  alias Web.Race
  alias Web.Router.Helpers, as: Routes

  def index(conn, _params) do
    races = Race.all(alpha: true)
    render(conn, :index, races: races)
  end

  def show(conn, %{"id" => id}) do
    case Race.get(id) do
      nil ->
        redirect(conn, to: Routes.public_page_path(conn, :index))

      race ->
        render(conn, :show, race: race, extended: true)
    end
  end
end
