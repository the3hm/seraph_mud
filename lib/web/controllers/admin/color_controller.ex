defmodule Web.Admin.ColorController do
  @moduledoc """
  Admin controller for managing custom color codes for the game UI.
  """

  use Web.AdminController

  plug(:ensure_admin!)

  alias Web.Color
  alias Web.ColorCode

  @doc """
  Displays the list of current color codes for editing.
  """
  def index(conn, _params) do
    color_codes = ColorCode.all()

    render(conn, :index, color_codes: color_codes)
  end

  @doc """
  Updates the color configuration with new values.
  """
  def update(conn, %{"colors" => params}) do
    Color.update(params)

    redirect(conn,
      to: ~p"/admin/colors",
      flash: [info: "Colors updated!"]
    )
  end

  @doc """
  Resets all colors to their default values.
  """
  def delete(conn, _params) do
    Color.reset()

    redirect(conn,
      to: ~p"/admin/colors",
      flash: [info: "Colors reset!"]
    )
  end
end
