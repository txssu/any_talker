defmodule AnyTalker.Repo do
  use Ecto.Repo,
    otp_app: :any_talker,
    adapter: Ecto.Adapters.Postgres
end
