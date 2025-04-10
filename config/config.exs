import Config

config :ex_venture,
  ecto_repos: [Data.Repo],
  namespace: Web,
  timezone: "America/New_York",
  version: "development"

config :ex_venture, :game,
  world: true,
  currency: "gold",
  timeout_seconds: 10 * 60,
  rand: :rand,
  random_effect_range: -25..25,
  report_players: true

config :ex_venture, :npc, reaction_time_ms: 750

config :ex_venture, :cluster, size: 1

config :ex_venture, :errors, report: false

# Configures the endpoint
config :ex_venture, Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7mps3fp2M1dk3Cnd8Wu/91TdGWhzrh3PC3naZcn/umPyZabQQL2Zq8yysm9WMkc3",
  render_errors: [view: Web.ErrorView, accepts: ~w(html json)],
  pubsub_server: Web.PubSub

config :prometheus, Metrics.PipelineInstrumenter,
  labels: [:status_class, :method, :host, :scheme],
  duration_buckets: [
    10,
    100,
    1_000,
    10_000,
    100_000,
    300_000,
    500_000,
    750_000,
    1_000_000,
    1_500_000,
    2_000_000,
    3_000_000
  ],
  registry: :default,
  duration_unit: :microseconds

config :gossip, :callback_modules,
  core: Game.Gossip,
  players: Game.Gossip,
  tells: Game.Gossip,
  games: Game.Gossip

config :ex_venture, Game.Gettext, default_locale: "en"

config :mime, :types, %{
  "application/hal+json" => ["hal"],
  "application/vnd.siren+json" => ["siren"],
  "application/vnd.collection+json" => ["collection"],
  "application/vnd.mason+json" => ["mason"],
  "application/vnd.api+json" => ["jsonapi"]
}

config :phoenix, :format_encoders,
  collection: Jason,
  hal: Jason,
  mason: Jason,
  siren: Jason,
  jsonapi: Jason

config :phoenix, :json_library, Jason

config :ueberauth, Ueberauth,
  providers: [
    grapevine: {Grapevine.Ueberauth.Strategy, [scope: "profile email"]}
  ]

import_config "#{Mix.env()}.exs"
