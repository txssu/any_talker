import Config

config :any_talker, AnyTalker.Mailer, adapter: Swoosh.Adapters.Test
config :any_talker, AnyTalker.PromEx, disabled: true

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :any_talker, AnyTalker.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "any_talker_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :any_talker, AnyTalkerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "IRJWbTbBFdPAtYWk8k3kzxnkHaMJWHknrNt76tJ00fpa6SpTqa02/ykNpKhJBgjC",
  server: false

config :any_talker, Oban, testing: :inline

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false
