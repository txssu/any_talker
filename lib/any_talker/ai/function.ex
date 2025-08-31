defmodule AnyTalker.AI.Function do
  @moduledoc false
  @callback name() :: String.t()
  @callback spec() :: map()
  @callback exec(map(), map()) :: term()
end
