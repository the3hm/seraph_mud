defmodule Web.Admin.NPCControllerTest do
  use Web.AuthConnCase

  test "new npc", %{conn: conn} do
    params = %{
      "name" => "Bandit",
      "level" => "1",
      "experience_points" => "124",
      "currency" => "10",
      "stats" => base_stats() |> Jason
.encode!(),
    }

    conn = post conn, npc_path(conn, :create), npc: params
    assert html_response(conn, 302)
  end

  test "update a npc", %{conn: conn} do
    npc = create_npc(%{name: "Bandit"})

    conn = put conn, npc_path(conn, :update, npc.id), npc: %{name: "Barbarian"}
    assert html_response(conn, 302)
  end
end
