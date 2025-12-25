defmodule AnyTalker.AI.FunctionContext do
  @moduledoc false
  defstruct [:chat, :user, :message]

  @type t :: %__MODULE__{}
end
