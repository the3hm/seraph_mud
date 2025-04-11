defmodule Web.Admin.NPCSkillController do
  @moduledoc """
  Admin controller for assigning and removing trainable skills to NPCs.
  """

  use Web.AdminController

  alias Web.NPC
  alias Web.Skill

  @doc """
  Renders a form to add a trainable skill to an NPC.
  """
  def new(conn, %{"npc_id" => npc_id}) do
    npc = NPC.get(npc_id)

    render(conn, :new,
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
        redirect(conn,
          to: ~p"/admin/npcs/#{npc.id}",
          flash: [info: "Skill added to #{npc.name}!"]
        )

      {:error, _changeset} ->
        render(conn, :new,
          npc: npc,
          skills: Skill.all(),
          error_flash: "There was a problem adding the skill. Please try again."
        )
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
            redirect(conn,
              to: ~p"/admin/npcs/#{npc.id}",
              flash: [info: "Skill removed!"]
            )

          {:error, _changeset} ->
            redirect(conn,
              to: ~p"/admin/npcs/#{npc.id}",
              flash: [error: "There was a problem removing the skill. Please try again."]
            )
        end

      :error ->
        redirect(conn,
          to: ~p"/admin/npcs/#{npc.id}",
          flash: [error: "Invalid skill ID."]
        )
    end
  end
end
