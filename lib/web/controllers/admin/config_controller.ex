defmodule Web.Admin.ConfigController do
  @moduledoc """
  Admin controller for managing global game configuration settings.
  """

  use Web.AdminController

  plug :ensure_admin!

  alias Web.Config

  @doc """
  Render the index page for config settings.
  """
  def index(conn, _params) do
    render(conn, "index.html")
  end

  @doc """
  Render the edit form for an existing config or show the creation form for a new config key.
  """
  def edit(conn, %{"id" => name}) do
    case Config.get(name) do
      nil ->
        changeset = Config.new(name)

        conn
        |> assign(:name, name)
        |> assign(:changeset, changeset)
        |> render("new.html")

      config ->
        changeset = Config.edit(config)

        conn
        |> assign(:config, config)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end

  @doc """
  Handle updating of an existing config entry.
  """
  def update(conn, %{"id" => name, "config" => %{"value" => value}}) do
    case Config.update(name, value) do
      {:ok, _config} ->
        conn
        |> put_flash(:info, "Config updated!")
        |> redirect(to: config_path(conn, :index))

      {:error, changeset} ->
        config = Config.get(name)

        conn
        |> put_flash(:error, "There was an issue updating the config. Please try again.")
        |> assign(:config, config)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
