defmodule Web.Admin.WeatherController do
  use Web.AdminController

  plug(Web.Plug.FetchPage when action in [:index])

  alias Web.Weather

  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "weather", %{})
    %{page: weathers, pagination: pagination} = Weather.all(filter: filter, page: page, per: per)

    conn
    |> assign(:weathers, weathers)
    |> assign(:filter, filter)
    |> assign(:pagination, pagination)
    |> render("index.html")
  end

  def show(conn, %{"id" => id}) do
    weather = Weather.get(id)

    conn
    |> assign(:weather, weather)
    |> render("show.html")
  end

  def new(conn, _params) do
    changeset = Weather.new()

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"weather" => params}) do
    case Weather.create(params) do
      {:ok, weather} ->
        conn
        |> put_flash(:info, "#{weather.key} created!")
        |> redirect(to: weather_path(conn, :show, weather.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was a problem creating the weather. Please try again.")
        |> assign(:changeset, changeset)
        |> render("new.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    weather = Weather.get(id)
    changeset = Weather.edit(weather)

    conn
    |> assign(:weather, weather)
    |> assign(:changeset, changeset)
    |> render("edit.html")
  end

  def update(conn, %{"id" => id, "weather" => params}) do
    case Weather.update(id, params) do
      {:ok, weather} ->
        conn
        |> put_flash(:info, "#{weather.key} updated!")
        |> redirect(to: weather_path(conn, :show, weather.id))

      {:error, changeset} ->
        weather = Weather.get(id)

        conn
        |> put_flash(:error, "There was a problem updating #{weather.key}. Please try again.")
        |> assign(:weather, weather)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  def delete(conn, %{"id" => id}) do
    case Weather.delete(id) do
      {:ok, weather} ->
        conn
        |> put_flash(:info, "#{weather.key} has been deleted!")
        |> redirect(to: weather_path(conn, :index))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was an issue deleting the weather. Please try again.")
        |> redirect(to: weather_path(conn, :index))
    end
  end
end
