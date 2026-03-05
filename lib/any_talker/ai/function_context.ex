defmodule AnyTalker.AI.FunctionContext do
  @moduledoc false
  defstruct [:chat, :user, :message, :text]

  @type t :: %__MODULE__{}
end
