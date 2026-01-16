defmodule AnyTalker.AI.Response do
  @moduledoc false
  alias __MODULE__

  defmodule Usage do
    @moduledoc false
    defstruct [:total_tokens]
  end

  defstruct [:data, :usage]

  @type t :: %__MODULE__{}

  def total_tokens(%__MODULE__{usage: %Usage{total_tokens: total}}), do: total
  def total_tokens(%__MODULE__{}), do: 0

  defimpl AnyTalker.AI.ToMessage do
    def to_message(%Response{} = resp) do
      AnyTalker.AI.ToMessage.to_message(resp.data)
    end
  end
end
