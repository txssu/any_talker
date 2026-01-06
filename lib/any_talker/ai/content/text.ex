defmodule AnyTalker.AI.Content.Text do
  @moduledoc false
  alias __MODULE__

  defstruct [:text]

  def new(text) do
    %__MODULE__{text: text}
  end

  defimpl AnyTalker.AI.OpenRouter.Completions.Encoder do
    def encode(%Text{text: text}) do
      %{
        "type" => "text",
        "text" => text
      }
    end
  end
end
