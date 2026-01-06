[
  import_deps: [:ecto, :ecto_sql, :phoenix, :pathex],
  subdirectories: ["priv/*/migrations"],
  plugins: [TailwindFormatter, Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"],
  line_length: 120
]
