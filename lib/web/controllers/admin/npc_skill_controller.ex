defmodule Web.Admin.NPCSkillController do
  @moduledoc """
  Admin controller for assigning and removing trainable skills to NPCs.
  """

  use Web.AdminController

  alias Web.NPC
  alias Web.Skill
  alias Web.Router.Helpers, as: Routes

  @doc """
  Renders a form to add a trainable skill to an NPC.
  """
  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    render(conn, "new.html",
      npc: npc,
      skills: Skill.all()
    )
  end

  @doc """
  Creates a trainable skill entry for the given NPC.
  """
  def create(conn, %{"npc_id" => npc_id, "skill" => %{"id" => skill_id}}) do
    npc = NPC.get(npc_id)

    case NPC.add_trainable_skill(npc, skill_id) do
      {:ok, npc} ->
        conn
        |> put_flash(:info, "Skill added to #{npc.name}!")
        |> redirect(to: Routes.admin_npc_path(conn, :show, npc.id))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem adding the skill. Please try again.")
        |> assign(:npc, npc)
        |> assign(:skills, Skill.all())
        |> render("new.html")
    end
  end

  @doc """
  Removes a trainable skill from the given NPC.
  """
  def delete(conn, %{"npc_id" => npc_id, "id" => skill_id}) do
    npc = NPC.get(npc_id)

    case Integer.parse(skill_id) do
      {skill_id_int, _} ->
        case NPC.remove_trainable_skill(npc, skill_id_int) do
          {:ok, npc} ->
            conn
            |> put_flash(:info, "Skill removed!")
            |> redirect(to: Routes.admin_npc_path(conn, :show, npc.id))

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "There was a problem removing the skill. Please try again.")
            |> redirect(to: Routes.admin_npc_path(conn, :show, npc.id))
        end

      :error ->
        conn
        |> put_flash(:error, "Invalid skill ID.")
        |> redirect(to: Routes.admin_npc_path(conn, :show, npc.id))
    end
  end
end
