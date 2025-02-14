defmodule JokerCynic.Cache do
  @moduledoc false
  use Nebulex.Cache,
    otp_app: :joker_cynic,
    adapter: Nebulex.Adapters.Local
end
