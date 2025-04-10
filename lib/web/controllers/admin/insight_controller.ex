defmodule Web.Admin.InsightController do
  @moduledoc """
  Admin controller for viewing system insights.

  Currently renders a static insights dashboard. Future expansion may include
  graphs, analytics, or logs for system monitoring.
  """

  use Web.AdminController

  @doc """
  Render the admin insights dashboard.
  """
  def index(conn, _params) do
    render(conn, "index.html")
  end
end
