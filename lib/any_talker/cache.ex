defmodule AnyTalker.Cache do
  @moduledoc false
  use Nebulex.Cache,
    otp_app: :any_talker,
    adapter: Nebulex.Adapters.Local
end
