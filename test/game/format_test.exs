defmodule Game.FormatTest do
  use ExUnit.Case
  doctest Game.Format

  alias Game.Format

  describe "line wrapping" do
    test "single line" do
      assert Format.wrap("one line") == "one line"
    end

    test "wraps at 80 chars" do
      assert Format.wrap("this line will be split up into two lines because it is longer than 80 characters") ==
        "this line will be split up into two lines because it is longer than 80\ncharacters"
    end

    test "wraps at 80 chars - ignores {color} codes when counting" do
      line = "{blue}this{/blue} line {yellow}will be{/yellow} split up into two lines because it is longer than 80 characters"
      assert Format.wrap(line) ==
        "{blue}this{/blue} line {yellow}will be{/yellow} split up into two lines because it is longer than 80\ncharacters"
    end

    test "wraps at 80 chars - ignores {command} codes when counting" do
      line =
        "{command send='help text'}this{/command} line {yellow}will be{/yellow} split up into two lines because it is longer than 80 characters"
      assert Format.wrap(line) ==
        "{command send='help text'}this{/command} line {yellow}will be{/yellow} split up into two lines because it is longer than 80\ncharacters"
    end

    test "wraps and does not chuck newlines" do
      assert Format.wrap("hi\nthere") == "hi\nthere"
      assert Format.wrap("hi\n\n\nthere") == "hi\n\n\nthere"
    end
  end

  describe "inventory formatting" do
    setup do
      wearing = %{chest: %{name: "Leather Armor"}}
      wielding = %{right: %{name: "Short Sword"}, left: %{name: "Shield"}}
      items = [
        %{item: %{name: "Potion"}, quantity: 2},
        %{item: %{name: "Dagger"}, quantity: 1},
      ]

      %{currency: 10, wearing: wearing, wielding: wielding, items: items}
    end

    test "displays currency", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You have 10 gold/, Format.inventory(currency, wearing, wielding, items))
    end

    test "displays wielding", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You are wielding/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- a {item}Shield{\/item} in your left hand/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- a {item}Short Sword{\/item} in your right hand/, Format.inventory(currency, wearing, wielding, items))
    end

    test "displays wearing", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You are wearing/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- a {item}Leather Armor{\/item} on your chest/, Format.inventory(currency, wearing, wielding, items))
    end

    test "displays items", %{currency: currency, wearing: wearing, wielding: wielding, items: items} do
      Regex.match?(~r/You are holding:/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- {item}Potion x2{\/item}/, Format.inventory(currency, wearing, wielding, items))
      Regex.match?(~r/- {item}Dagger{\/item}/, Format.inventory(currency, wearing, wielding, items))
    end
  end

  describe "info formatting" do
    setup do
      stats = %{
        health_points: 50,
        max_health_points: 55,
        skill_points: 10,
        max_skill_points: 10,
        endurance_points: 10,
        max_endurance_points: 10,
        strength: 10,
        agility: 10,
        intelligence: 10,
        awareness: 10,
        vitality: 10,
        willpower: 10,
      }

      save = %Data.Save{level: 1, experience_points: 0, spent_experience_points: 0, stats: stats}

      user = %{
        name: "hero",
        save: save,
        race: %{name: "Human"},
        class: %{name: "Fighter"},
        seconds_online: 61,
      }

      %{user: user}
    end

    test "includes player name", %{user: user} do
      assert Regex.match?(~r/hero/, Format.info(user))
    end

    test "includes player race", %{user: user} do
      assert Regex.match?(~r/Human/, Format.info(user))
    end

    test "includes player class", %{user: user} do
      assert Regex.match?(~r/Fighter/, Format.info(user))
    end

    test "includes player level", %{user: user} do
      assert Regex.match?(~r/Level.+|.+1/, Format.info(user))
    end

    test "includes player xp", %{user: user} do
      assert Regex.match?(~r/XP.+|.+0/, Format.info(user))
    end

    test "includes player spent xp", %{user: user} do
      assert Regex.match?(~r/Spent XP.+|.+0/, Format.info(user))
    end

    test "includes player health", %{user: user} do
      assert Regex.match?(~r/Health.+|.+50\/55/, Format.info(user))
    end

    test "includes player skill points", %{user: user} do
      assert Regex.match?(~r/Skill Points.+|.+10\/10/, Format.info(user))
    end

    test "includes player endurance points", %{user: user} do
      assert Regex.match?(~r/Stamina.+|.+10\/10/, Format.info(user))
    end

    test "includes player strength", %{user: user} do
      assert Regex.match?(~r/Strength.+|.+10/, Format.info(user))
    end

    test "includes player agility", %{user: user} do
      assert Regex.match?(~r/Agility.+|.+10/, Format.info(user))
    end

    test "includes player intelligence", %{user: user} do
      assert Regex.match?(~r/Intelligence.+|.+10/, Format.info(user))
    end

    test "includes player awareness", %{user: user} do
      assert Regex.match?(~r/Awareness.+|.+10/, Format.info(user))
    end

    test "includes player vitality", %{user: user} do
      assert Regex.match?(~r/Vitality.+|.+10/, Format.info(user))
    end

    test "includes player willpower", %{user: user} do
      assert Regex.match?(~r/Willpower.+|.+10/, Format.info(user))
    end

    test "includes player play time", %{user: user} do
      assert Regex.match?(~r/Play Time.+|.+00h 01m 01s/, Format.info(user))
    end
  end

  describe "shop listing" do
    setup do
      sword = %{name: "Sword", price: 100, quantity: 10}
      shield = %{name: "Shield", price: 80, quantity: -1}
      %{shop: %{name: "Tree Top Stand"}, items: [sword, shield]}
    end

    test "includes shop name", %{shop: shop, items: items} do
      assert Regex.match?(~r/Tree Top Stand/, Format.list_shop(shop, items))
    end

    test "includes shop items", %{shop: shop, items: items} do
      assert Regex.match?(~r/100 gold/, Format.list_shop(shop, items))
      assert Regex.match?(~r/10 left/, Format.list_shop(shop, items))
      assert Regex.match?(~r/Sword/, Format.list_shop(shop, items))
    end

    test "-1 quantity is unlimited", %{shop: shop, items: items} do
      assert Regex.match?(~r/unlimited/, Format.list_shop(shop, items))
    end
  end

  describe "npc status line" do
    setup do
      npc = %{name: "Guard", extra: %{status_line: "[name] is here.", is_quest_giver: false}}

      %{npc: npc}
    end

    test "templates the name in", %{npc: npc} do
      assert Format.npc_name_for_status(npc) == "{npc}Guard{/npc}"
      assert Format.npc_status(npc) == "{npc}Guard{/npc} is here."
    end

    test "if a quest giver it includes a quest mark", %{npc: npc} do
      npc = %{npc | extra: Map.put(npc.extra, :is_quest_giver, true)}
      assert Format.npc_name_for_status(npc) == "{npc}Guard{/npc} ({quest}!{/quest})"
      assert Format.npc_status(npc) == "{npc}Guard{/npc} ({quest}!{/quest}) is here."
    end
  end
end
