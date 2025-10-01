defmodule AnyTalker.AI.Message.FunctionToolCall do
  @moduledoc """
  Function tool call message for AI chat completion requests.

  Represents a call to a function tool created by the model.
  Corresponds to ChatCompletionMessageToolCall in the OpenAI API.

  ## Fields

  | Field Name | Type | Description |
  |------------|------|-------------|
  | call_id | String | The ID of the tool call |
  | name | String | The name of the function to call |
  | arguments | String | The arguments to call the function with, as JSON |

  ## Examples

      FunctionToolCall.new("call_123", "get_weather", "{\"location\": \"London\"}")

      FunctionToolCall.new("call_456", "calculate", "{\"operation\": \"add\", \"a\": 1, \"b\": 2}")
  """

  @behaviour AnyTalker.AI.Message.Behaviour

  defstruct call_id: nil,
            name: nil,
            arguments: nil

  @doc """
  Creates a new FunctionToolCall message.

  ## Examples

      FunctionToolCall.new("call_123", "get_weather", "{\"location\": \"London\"}")
  """
  def new(call_id, name, arguments) when is_binary(call_id) and is_binary(name) and is_binary(arguments) do
    %__MODULE__{
      call_id: call_id,
      name: name,
      arguments: arguments
    }
  end

  @impl AnyTalker.AI.Message.Behaviour
  def format_message(%__MODULE__{} = message) do
    %{
      call_id: message.call_id,
      type: "function_call",
      name: message.name,
      arguments: message.arguments
    }
  end
end
