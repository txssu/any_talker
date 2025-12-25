defmodule AnyTalker.AI.Message do
  @moduledoc false

  alias __MODULE__
  alias AnyTalker.AI.Content.Image
  alias AnyTalker.AI.Content.Text

  defstruct [:uniq_key, :role, :content, :tool_calls, :tool_call_id, :reasoning_details]

  @type t :: %__MODULE__{}

  def new(uniq_key, role, text, image) do
    content =
      []
      |> append_not_nil(image && Image.new(image))
      |> append_not_nil(text && Text.new(text))
      |> Enum.reverse()

    %__MODULE__{
      role: role,
      content: content,
      uniq_key: uniq_key
    }
  end

  defp append_not_nil(lst, nil), do: lst
  defp append_not_nil(lst, value), do: [value | lst]

  defimpl AnyTalker.AI.OpenRouter.Completions.Encoder do
    def encode(%Message{} = msg) do
      data =
        AnyTalker.MapExt.reject_nil_values(%{
          "role" => msg.role,
          "content" => encode_content(msg.content),
          "tool_calls" => msg.tool_calls,
          "tool_call_id" => msg.tool_call_id,
          "reasoning_details" => msg.reasoning_details
        })

      [data]
    end

    def encode_content(nil), do: nil
    def encode_content(content), do: Enum.map(content, &AnyTalker.AI.OpenRouter.Completions.Encoder.encode/1)
  end
end
