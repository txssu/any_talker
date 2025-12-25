defmodule AnyTalker.AI.Response.TextOutput do
  @moduledoc false
  alias __MODULE__

  defstruct [:content]

  defimpl AnyTalker.AI.ToMessage do
    def to_message(%TextOutput{content: text}) do
      content =
        text
        |> AnyTalker.AI.Content.Text.new()
        |> List.wrap()

      %AnyTalker.AI.Message{role: "assistant", content: content}
    end
  end
end
