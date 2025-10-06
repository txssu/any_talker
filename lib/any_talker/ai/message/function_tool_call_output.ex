defmodule AnyTalker.AI.Message.FunctionToolCallOutput do
  @moduledoc """
  Function tool call output message for AI chat completion requests.

  Represents the result of a function tool call, sent back to the model.
  Corresponds to ChatCompletionRequestToolMessage in the OpenAI API.

  ## Fields

  | Field Name | Type | Description |
  |------------|------|-------------|
  | call_id | String | The ID of the tool call this message is responding to |
  | output | String | The output of the tool, as text or JSON |
  | id | String | Optional ID field |

  ## Examples

      FunctionToolCallOutput.new("call_123", "{\"temperature\": 22, \"condition\": \"sunny\"}")

      FunctionToolCallOutput.new("call_456", "Result: 3")
  """

  @behaviour AnyTalker.AI.Message.Behaviour

  defstruct call_id: nil,
            output: nil,
            id: nil

  @doc """
  Creates a new FunctionToolCallOutput message.

  ## Examples

      FunctionToolCallOutput.new("call_123", "{\"result\": \"success\"}")
  """
  def new(call_id, output) when is_binary(call_id) and is_binary(output) do
    %__MODULE__{
      call_id: call_id,
      output: output,
      id: Ecto.UUID.generate()
    }
  end

  @impl AnyTalker.AI.Message.Behaviour
  def format_message(%__MODULE__{} = message) do
    %{
      type: "function_call_output",
      call_id: message.call_id,
      output: message.output,
      id: message.id
    }
  end
end
