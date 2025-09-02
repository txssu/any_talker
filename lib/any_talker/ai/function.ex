defmodule AnyTalker.AI.Function do
  @moduledoc false
  @callback name() :: String.t()
  @callback exec(map(), map()) :: term()
end
