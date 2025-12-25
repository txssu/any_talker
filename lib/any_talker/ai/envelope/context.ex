defmodule AnyTalker.AI.Envelope.Context do
  @moduledoc false
  defstruct [:chat, :author, :bot_id]

  @type t :: %__MODULE__{}
end
