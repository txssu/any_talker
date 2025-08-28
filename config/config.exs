# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :any_talker, AnyTalker.Mailer, adapter: Swoosh.Adapters.Local

# Configures the endpoint
config :any_talker, AnyTalkerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AnyTalkerWeb.ErrorHTML, json: AnyTalkerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AnyTalker.PubSub,
  live_view: [signing_salt: "jARMyT1A"]

config :any_talker, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10],
  repo: AnyTalker.Repo,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"30 18 * * *", AnyTalker.Counters.NikitaCounterJob}
     ]}
  ]

config :any_talker,
  ecto_repos: [AnyTalker.Repo],
  generators: [timestamp_type: :utc_datetime]

config :any_talker,
  nikita_id: 632_365_722,
  nikita_chat_id: -1_002_634_925_169,
  nikita_counter_timeout_min: 1

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  any_talker: [
    args:
      ~w(js/app.js js/telegram.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :ex_gram, adapter: ExGram.Adapter.TeslaNoDebug

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: {AnyTalker.LogFormatter, :format},
  metadata: [:request_id, :error_details]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  any_talker: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :tesla, disable_deprecated_builder_warning: true

import_config "#{config_env()}.exs"
