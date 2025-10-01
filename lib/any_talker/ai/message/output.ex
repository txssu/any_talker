defmodule AnyTalker.AI.Message.Output do
  @moduledoc """
  Output message for AI chat completion responses.

  Represents messages sent by the model in response to user messages.
  Corresponds to ChatCompletionRequestAssistantMessage in the OpenAI API.

  ## Fields

  | Field Name | Type | Description |
  |------------|------|-------------|
  | message_id | String | Unique identifier for the message |
  | chat_id | Integer | The chat identifier |
  | user_id | Integer | The user identifier |
  | role | Atom | The role of the message author (always `:assistant`) |
  | text | String | The text content of the message |
  | sent_at | DateTime | When the message was sent |
  | reply | Input \| Output | Optional reply message (message being replied to) |
  | quote | String | Optional quoted text from a reply |
  | refusal | String | Optional refusal message if the model refused to respond |

  ## Examples

      Output.new("msg_1", "Hello, how can I help?", ~U[2024-01-01 00:00:00Z])

      Output.new("msg_2", nil, ~U[2024-01-01 00:00:00Z],
        refusal: "I cannot help with that request"
      )
  """

  @behaviour AnyTalker.AI.Message.Behaviour

  defstruct message_id: nil,
            chat_id: nil,
            user_id: nil,
            role: :assistant,
            text: nil,
            sent_at: nil,
            reply: nil,
            quote: nil,
            refusal: nil

  @doc """
  Creates a new Output message.

  ## Examples

      Output.new("msg_1", "Hello", ~U[2024-01-01 00:00:00Z])

      Output.new("msg_1", nil, ~U[2024-01-01 00:00:00Z],
        refusal: "I cannot help with that"
      )
  """
  def new(message_id, text, sent_at, options \\ []) do
    %__MODULE__{
      message_id: message_id,
      text: text,
      sent_at: sent_at,
      user_id: options[:user_id],
      chat_id: options[:chat_id],
      reply: options[:reply],
      quote: options[:quote],
      refusal: options[:refusal]
    }
  end

  @impl AnyTalker.AI.Message.Behaviour
  def format_message(%__MODULE__{refusal: refusal}) when is_binary(refusal) do
    %{
      role: :assistant,
      refusal: refusal,
      content: nil
    }
  end

  def format_message(%__MODULE__{} = message) do
    %{
      role: :assistant,
      content: build_json_content(message)
    }
  end

  defp build_json_content(message) do
    %{}
    |> maybe_add_text(message)
    |> maybe_add_quote(message)
    |> add_sent_at(message)
    |> Jason.encode!()
  end

  defp maybe_add_text(content, %__MODULE__{text: text}) when is_binary(text) do
    Map.put(content, :text, text)
  end

  defp maybe_add_text(content, _message), do: content

  defp maybe_add_quote(content, %__MODULE__{reply: reply}) when is_struct(reply) do
    case reply do
      %__MODULE__{quote: quote} when is_binary(quote) ->
        Map.put(content, :quote, quote)

      %AnyTalker.AI.Message.Input{quote: quote} when is_binary(quote) ->
        Map.put(content, :quote, quote)

      _reply ->
        content
    end
  end

  defp maybe_add_quote(content, _other), do: content

  defp add_sent_at(content, %__MODULE__{sent_at: sent_at}) do
    yekaterinburg_sent_at =
      sent_at
      |> DateTime.shift_zone!("Asia/Yekaterinburg")
      |> DateTime.truncate(:second)

    Map.put(content, :sent_at, DateTime.to_iso8601(yekaterinburg_sent_at))
  end
end
