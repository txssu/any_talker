defmodule AnyTalker.AI.Response do
  @moduledoc false
  alias __MODULE__

  defstruct [:data]

  @type t :: %__MODULE__{}

  defimpl AnyTalker.AI.ToMessage do
    def to_message(%Response{} = resp) do
      AnyTalker.AI.ToMessage.to_message(resp.data)
    end
  end
end
