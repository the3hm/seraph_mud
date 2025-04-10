defmodule Web.HelpController do
  @moduledoc """
  Public-facing help topic viewer.
  """

  use Web, :controller

  alias Game.Help
  alias Game.Proficiencies
  alias Web.HelpTopic
  alias Web.Router.Helpers, as: Routes

  def index(conn, _params) do
    help_topics = HelpTopic.all(alpha: true)
    render(conn, "index.html", help_topics: help_topics)
  end

  def show(conn, %{"id" => id}) do
    case HelpTopic.get(id) do
      nil ->
        redirect(conn, to: Routes.public_page_path(conn, :index))

      help_topic ->
        render(conn, "show.html", help_topic: help_topic)
    end
  end

  def commands(conn, _params) do
    commands = HelpTopic.commands()
    render(conn, "commands.html", commands: commands)
  end

  def command(conn, %{"command" => command}) do
    with {:ok, command} <- HelpTopic.command(command),
         :ok <- check_user_allowed(conn, command) do
      render(conn, "command.html", command: command)
    else
      _ ->
        redirect(conn, to: Routes.public_page_path(conn, :index))
    end
  end

  def built_in(conn, %{"id" => id}) do
    case HelpTopic.built_in(id) do
      nil ->
        redirect(conn, to: Routes.public_page_path(conn, :index))

      built_in ->
        render(conn, "built_in.html", built_in: built_in)
    end
  end

  def proficiency(conn, %{"id" => id}) do
    with {id, _} <- Integer.parse(id),
         {:ok, proficiency} <- Proficiencies.get(id) do
      render(conn, "proficiency.html", proficiency: proficiency)
    else
      _ ->
        redirect(conn, to: Routes.public_page_path(conn, :index))
    end
  end

  defp check_user_allowed(conn, command) do
    flags =
      conn.assigns
      |> Map.get(:user, %{})
      |> Map.get(:flags, [])

    if Help.allowed?(command, flags), do: :ok, else: {:error, :not_allowed}
  end
end
