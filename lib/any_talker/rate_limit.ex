defmodule AnyTalker.RateLimit do
  @moduledoc false
  use Hammer, backend: :atomic
end
