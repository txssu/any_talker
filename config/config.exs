# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  joker_cynic: [
    args:
      ~w(js/app.js js/telegram.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :joker_cynic, JokerCynic.AI.ContextStorage,
  gc_interval: :timer.hours(12),
  max_size: 1_000_000,
  allocated_memory: 2_000_000_000,
  gc_cleanup_min_timeout: :timer.seconds(10),
  gc_cleanup_max_timeout: :timer.minutes(10)

config :joker_cynic, JokerCynic.ChRepo, priv: "priv/ch_repo"

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :joker_cynic, JokerCynic.Mailer, adapter: Swoosh.Adapters.Local

# Configures the endpoint
config :joker_cynic, JokerCynicWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: JokerCynicWeb.ErrorHTML, json: JokerCynicWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: JokerCynic.PubSub,
  live_view: [signing_salt: "jARMyT1A"]

config :joker_cynic, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10],
  repo: JokerCynic.Repo,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"0 23 * * *", JokerCynic.Counters.NikitaCounterJob}
     ]}
  ]

config :joker_cynic,
  ecto_repos: [JokerCynic.Repo, JokerCynic.ChRepo],
  generators: [timestamp_type: :utc_datetime]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: {JokerCynic.LogFormatter, :format},
  metadata: [:request_id, :error_details]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  joker_cynic: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
