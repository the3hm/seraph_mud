defmodule Web.PageController do
  @moduledoc """
  Handles public-facing pages like the homepage, map, and Mudlet client integrations.
  """

  use Web, :controller

  alias Web.Announcement
  alias Web.Zone

  @doc """
  Renders the homepage with recent announcements.
  """
  def index(conn, _params) do
    render(conn, :index, announcements: Announcement.recent())
  end

  @doc """
  Returns the current ExVenture version and SHA.
  """
  def version(conn, _params) do
    text(conn, "#{ExVenture.version()} - #{ExVenture.sha_version()}")
  end

  @doc """
  Renders the Mudlet package XML used by the client.
  """
  def mudlet_package(conn, _params) do
    render(conn, :mudlet_package)
  end

  @doc """
  Renders the game map as XML.
  """
  def map(conn, _params) do
    render(conn, :map, zones: Zone.all())
  end

  @doc """
  Renders the web app manifest for PWA support.
  """
  def manifest(conn, _params) do
    conn
    |> put_resp_header("content-type", "application/manifest+json")
    |> render(:manifest)
  end
end
