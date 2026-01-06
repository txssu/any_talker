defmodule AnyTalker.AI.Request do
  @moduledoc false

  defstruct [:models, :messages, :tools, :instructions, :function_context]
  @type t :: %__MODULE__{}

  defimpl AnyTalker.AI.OpenRouter.Completions.Encoder do
    alias AnyTalker.AI.OpenRouter.Completions.Encoder
    alias AnyTalker.AI.Request

    def encode(%Request{} = request) do
      %{
        "models" => request.models,
        "messages" => Encoder.encode(request.instructions) ++ Enum.flat_map(request.messages, &Encoder.encode/1),
        "tools" => Enum.map(request.tools, &Encoder.encode/1)
      }
    end
  end
end
