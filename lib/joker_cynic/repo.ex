defmodule JokerCynic.Repo do
  use Ecto.Repo,
    otp_app: :joker_cynic,
    adapter: Ecto.Adapters.Postgres
end
