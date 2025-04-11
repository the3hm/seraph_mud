defmodule Web.ClassController do
  @moduledoc """
  Displays a list of classes and individual class info pages.
  """

  use Web, :controller

  alias Web.Class

  @doc """
  Lists all classes alphabetically.
  """
  def index(conn, _params) do
    render(conn, :index, classes: Class.all(alpha: true))
  end

  @doc """
  Shows a single class by ID, or redirects to the homepage if not found.
  """
  def show(conn, %{"id" => id}) do
    case Class.get(id) do
      nil ->
        redirect(conn, to: ~p"/")

      class ->
        render(conn, :show, class: class, extended: true)
    end
  end
end
