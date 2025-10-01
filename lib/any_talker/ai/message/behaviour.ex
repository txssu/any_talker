defmodule AnyTalker.AI.Message.Behaviour do
  @moduledoc """
  Behaviour for formatting different types of AI messages.

  This behaviour defines the contract for any message module that can be formatted
  for the OpenAI Chat Completions API. Implementations should handle the formatting
  of specific message types (input, output, tool calls, tool results).

  ## Example

      defmodule AnyTalker.AI.Message.Input do
        @behaviour AnyTalker.AI.Message.Behaviour

        @impl AnyTalker.AI.Message.Behaviour
        def format_message(%__MODULE__{} = message) do
          # Format input message logic
        end
      end
  """

  @doc """
  Formats the message into a structure compatible with OpenAI Chat Completions API.

  Returns a map with `:role` and `:content` keys, or a map with `:role`, `:tool_calls`,
  and `:content` keys for messages with tool calls.

  ## Examples

      format_message(%Input{role: :user, text: "Hello"})
      #=> %{role: :user, content: "..."}

      format_message(%FunctionToolCall{id: "1", name: "get_weather", arguments: "{}"})
      #=> %{role: :assistant, tool_calls: [...], content: nil}
  """
  @callback format_message(message :: struct()) :: map()
end
