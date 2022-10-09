defmodule ExVenture.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_venture,
      version: "0.29.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      deps: deps(),
      aliases: aliases(),
      releases: releases(),
      source_url: "https://github.com/oestrich/ex_venture",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger], mod: {ExVenture.Application, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:my_app, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:bamboo, "~> 1.0"},
      {:bamboo_smtp, "~> 1.5"},
      {:bcrypt_elixir, "~> 2.0"},
      {:cachex, "~> 3.0"},
      {:cowboy, "~> 2.0"},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:earmark, "~> 1.4.0"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:elixir_uuid, "~> 1.2"},
      {:eqrcode, "~> 0.1.5"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:font_awesomex, "~> 4.0.0"},
      {:gettext, "~> 0.17.0"},
      {:gossip, "~> 1.0"},
      {:libcluster, "~> 3.0", only: [:dev, :prod]},
      {:logger_file_backend, "~> 0.0.10"},
      {:logster, "~> 1.0"},
      {:phoenix, "~> 1.3"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_inline_svg, "~> 1.4"},
      {:plug_cowboy, "~> 2.0", override: true},
      {:pid_file, "~> 0.1.0"},
      {:prometheus_ex, git: "https://github.com/deadtrickster/prometheus.ex.git", override: true},
      {:prometheus_plugs, "~> 1.1"},
      {:poison, "~> 3.1"},
      {:pot, git: "https://github.com/yuce/pot.git"},
      {:postgrex, ">= 0.0.0"},
      {:oauth2, "~> 0.9"},
      {:ranch, "~> 1.6"},
      {:sentry, "~> 7.0"},
      {:squabble, git: "https://github.com/oestrich/squabble.git"},
      {:telemetry, "~> 0.3"},
      {:timex, "~> 3.7.6"},
      {:ueberauth, "~> 0.7.0"},
      {:yaml_elixir, "~> 2.8.0"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate.reset": ["ecto.drop", "ecto.create", "ecto.migrate"]
    ]
  end

  defp releases() do
    [
      ex_venture: [
        include_executables_for: [:unix],
        applications: [
          runtime_tools: :permanent
        ],
        config_providers: [{ExVenture.ConfigProvider, "/etc/exventure.config.exs"}]
      ]
    ]
  end
end
