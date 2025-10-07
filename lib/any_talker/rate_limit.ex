defmodule AnyTalker.RateLimit do
  @moduledoc false
  use Hammer, backend: :atomic, algorithm: :sliding_window
end
