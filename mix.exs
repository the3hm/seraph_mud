defmodule ExVenture.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_venture,
      version: "0.1.0",
      elixir: "~> 1.18.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      compilers: [:yecc, :leex] ++ Mix.compilers(),
      aliases: aliases(),
      deps: deps(),
      releases: releases(),
      source_url: "https://github.com/the3hm/seraph_mud",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      mod: {ExVenture.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix & Web
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_dashboard, "~> 0.8.6"},
      {:plug_cowboy, "~> 2.7"},
      {:ranch, "~> 2.2"},
      {:pid_file, "~> 0.2.0"},
      {:phoenix_html_helpers, "~> 1.0"},

      # Email
      {:bamboo, "~> 2.2"},

      # Database & Persistence
      {:ecto_sql, "~> 3.12"},
      {:phoenix_ecto, "~> 4.6"},
      {:postgrex, ">= 0.20.0"},
      {:yaml_elixir, "~> 2.11"},
      {:cachex, "~> 4.0"},

      # Authentication
      {:bcrypt_elixir, "~> 3.2"},
      {:oauth2, "~> 2.1"},
      {:ueberauth, "~> 0.10.8"},
      {:pot, "~> 1.0"},
      {:eqrcode, "~> 0.2.1"},

      # Documentation
      {:earmark, "~> 1.4"},
      {:ex_doc, "~> 0.37.3", only: :dev, runtime: false},

      # Data Generation / Testing
      {:ex_machina, "~> 2.8", only: :test},
      {:faker, "~> 0.18", only: [:dev, :test]},

      # Background Jobs
      {:oban, "~> 2.19"},

      # PubSub / Concurrency
      {:phoenix_pubsub, "~> 2.1"},
      {:squabble, git: "https://github.com/oestrich/squabble.git"},

      # Observability / Monitoring
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.0"},
      {:prometheus, "~> 4.10"},
      {:prometheus_plugs, "~> 1.1"},
      {:prometheus_ex, "~> 3.0"},

      # Parsing / DSL
      {:nimble_parsec, "~> 1.4"},

      # Internationalization & Formatting
      {:gettext, "~> 0.26.2"},

      # Utilities
      {:jason, "~> 1.4"},
      {:uuid, "~> 1.1"},
      {:swoosh, "~> 1.18"},
      {:finch, "~> 0.19.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:timex, "~> 3.7"},
      {:ex_unit_notifier, "~> 1.3"},
      {:libcluster, "~> 3.0", only: [:dev, :prod]},
      {:logger_file_backend, "~> 0.0.10"},
      {:logster, "~> 1.0"},
      {:sentry, "~> 10.9"},

      # Design
      {:fluxon, "~> 1.0.10", repo: :fluxon},
      {:tailwind, "~> 0.3.1", runtime: Mix.env() == :dev},
      {:backpex, "~> 0.12.0"},

      # Data Processing Pipelines
      {:broadway, "~> 1.2"},

      # Deprecated For Migration, Remove Eventually
      {:phoenix_view, "~> 2.0"},
      {:phoenix_inline_svg, "~> 1.4"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate.reset": ["ecto.drop", "ecto.create", "ecto.migrate"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind ex_venture", "esbuild ex_venture"],
      "assets.deploy": [
        "tailwind ex_venture --minify",
        "esbuild ex_venture --minify",
        "phx.digest"
      ]
    ]
  end

  defp releases do
    [
      ex_venture: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent],
        config_providers: [{ExVenture.ConfigProvider, "/etc/exventure.config.exs"}]
      ]
    ]
  end
end
