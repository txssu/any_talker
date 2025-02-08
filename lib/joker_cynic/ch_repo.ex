defmodule JokerCynic.ChRepo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :joker_cynic,
    adapter: Ecto.Adapters.ClickHouse
end
