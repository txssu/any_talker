defmodule AnyTalker.AI.Envelope.Context do
  @moduledoc false
  defstruct [:chat, :author, :bot_id, response_mode: :short]

  @type t :: %__MODULE__{}
end
