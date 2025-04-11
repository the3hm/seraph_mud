defmodule Web.HelpController do
  @moduledoc """
  Public-facing help topic viewer.
  """

  use Web, :controller

  alias Game.Help
  alias Game.Proficiencies
  alias Web.HelpTopic

  def index(conn, _params) do
    help_topics = HelpTopic.all(alpha: true)
    render(conn, :index, help_topics: help_topics)
  end

  def show(conn, %{"id" => id}) do
    case HelpTopic.get(id) do
      nil ->
        redirect(conn, to: ~p"/")

      help_topic ->
        render(conn, :show, help_topic: help_topic)
    end
  end

  def commands(conn, _params) do
    commands = HelpTopic.commands()
    render(conn, :commands, commands: commands)
  end

  def command(conn, %{"command" => command}) do
    with {:ok, command} <- HelpTopic.command(command),
         :ok <- check_user_allowed(conn, command) do
      render(conn, :command, command: command)
    else
      _ ->
        redirect(conn, to: ~p"/")
    end
  end

  def built_in(conn, %{"id" => id}) do
    case HelpTopic.built_in(id) do
      nil ->
        redirect(conn, to: ~p"/")

      built_in ->
        render(conn, :built_in, built_in: built_in)
    end
  end

  def proficiency(conn, %{"id" => id}) do
    with {id, _} <- Integer.parse(id),
         {:ok, proficiency} <- Proficiencies.get(id) do
      render(conn, :proficiency, proficiency: proficiency)
    else
      _ ->
        redirect(conn, to: ~p"/")
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
