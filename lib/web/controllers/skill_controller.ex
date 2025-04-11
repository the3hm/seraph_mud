defmodule Web.SkillController do
  @moduledoc """
  Displays a list of skills and individual skill detail pages.
  """

  use Web, :controller

  alias Web.Skill

  plug(Web.Plug.FetchPage, [per: 10] when action in [:index])

  @doc """
  Lists all enabled skills with pagination.
  """
  def index(conn, _params) do
    %{page: page, per: per} = conn.assigns

    %{page: skills, pagination: pagination} =
      Skill.all(page: page, per: per, filter: %{enabled: true})

    render(conn, :index,
      skills: skills,
      pagination: pagination
    )
  end

  @doc """
  Displays a single skill page.
  """
  def show(conn, %{"id" => id}) do
    case Skill.get(id) do
      nil ->
        redirect(conn, to: ~p"/")

      skill ->
        render(conn, :show, skill: skill)
    end
  end
end
