defmodule Web.Admin.WeatherController do
  @moduledoc """
  Admin controller for managing weather conditions used in the game world.
  Supports listing, creation, editing, and deletion.
  """

  use Web.AdminController

  alias Web.Router.Helpers, as: Routes
  alias Web.Weather

  plug(Web.Plug.FetchPage when action in [:index])

  @doc """
  Lists all weathers with optional filters and pagination.
  """
  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "weather", %{})

    %{page: weathers, pagination: pagination} =
      Weather.all(filter: filter, page: page, per: per)

    render(conn, "index.html",
      weathers: weathers,
      filter: filter,
      pagination: pagination
    )
  end

  @doc """
  Shows a single weather entry.
  """
  def show(conn, %{"id" => id}) do
    render(conn, "show.html", weather: Weather.get(id))
  end

  @doc """
  Renders the form for a new weather entry.
  """
  def new(conn, _params) do
    render(conn, "new.html", changeset: Weather.new())
  end

  @doc """
  Creates a new weather entry.
  """
  def create(conn, %{"weather" => params}) do
    case Weather.create(params) do
      {:ok, weather} ->
        conn
        |> put_flash(:info, "#{weather.key} created!")
        |> redirect(to: Routes.admin_weather_path(conn, :show, weather.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the weather. Please try again.")
        |> render("new.html", changeset: changeset)
    end
  end

  @doc """
  Renders the edit form for an existing weather entry.
  """
  def edit(conn, %{"id" => id}) do
    weather = Weather.get(id)

    render(conn, "edit.html",
      weather: weather,
      changeset: Weather.edit(weather)
    )
  end

  @doc """
  Updates a weather entry with new values.
  """
  def update(conn, %{"id" => id, "weather" => params}) do
    case Weather.update(id, params) do
      {:ok, weather} ->
        conn
        |> put_flash(:info, "#{weather.key} updated!")
        |> redirect(to: Routes.admin_weather_path(conn, :show, weather.id))

      {:error, changeset} ->
        weather = Weather.get(id)

        conn
        |> put_flash(:error, "There was a problem updating #{weather.key}. Please try again.")
        |> render("edit.html",
          weather: weather,
          changeset: changeset
        )
    end
  end

  @doc """
  Deletes a weather entry.
  """
  def delete(conn, %{"id" => id}) do
    case Weather.delete(id) do
      {:ok, weather} ->
        conn
        |> put_flash(:info, "#{weather.key} has been deleted!")
        |> redirect(to: Routes.admin_weather_path(conn, :index))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was an issue deleting the weather. Please try again.")
        |> redirect(to: Routes.admin_weather_path(conn, :index))
    end
  end
end
