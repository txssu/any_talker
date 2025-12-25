defmodule AnyTalker.AI.Response.ToolCall do
  @moduledoc false

  alias __MODULE__

  defstruct [:reasoning_details, :function_name, :arguments, :tool_call_id]

  defimpl AnyTalker.AI.ToMessage do
    def to_message(%ToolCall{} = tool_call) do
      %AnyTalker.AI.Message{
        role: "assistant",
        reasoning_details: tool_call.reasoning_details,
        tool_calls: [
          %{
            "id" => tool_call.tool_call_id,
            "type" => "function",
            "function" => %{
              "name" => tool_call.function_name,
              "arguments" => Jason.encode!(tool_call.arguments)
            }
          }
        ]
      }
    end
  end
end
