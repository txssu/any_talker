defmodule AnyTalker.AI.Message.Input do
  @moduledoc """
  Input message for AI chat completion requests.

  Represents messages sent by users or system, containing prompts or additional context.
  Corresponds to ChatCompletionRequestUserMessage and ChatCompletionRequestSystemMessage
  in the OpenAI API.

  ## Fields

  | Field Name | Type | Description |
  |------------|------|-------------|
  | message_id | String | Unique identifier for the message |
  | chat_id | Integer | The chat identifier |
  | user_id | Integer | The user identifier |
  | role | Atom | The role of the message author (`:user`, `:system`, `:developer`) |
  | username | String | Optional username of the sender |
  | text | String | The text content of the message |
  | sent_at | DateTime | When the message was sent |
  | reply | Input \| Output | Optional reply message (message being replied to) |
  | quote | String | Optional quoted text from a reply |
  | image_url | String | Optional URL of an attached image |

  ## Examples

      Input.new("msg_1", :user, "Hello", ~U[2024-01-01 00:00:00Z])

      Input.new("msg_2", :user, "Check this image", ~U[2024-01-01 00:00:00Z],
        username: "john",
        image_url: "https://example.com/image.jpg"
      )
  """

  @behaviour AnyTalker.AI.Message.Behaviour

  defstruct message_id: nil,
            chat_id: nil,
            user_id: nil,
            role: nil,
            username: nil,
            text: nil,
            sent_at: nil,
            reply: nil,
            quote: nil,
            image_url: nil

  @doc """
  Creates a new Input message.

  ## Examples

      Input.new("msg_1", :user, "Hello", ~U[2024-01-01 00:00:00Z])

      Input.new("msg_1", :user, "Hello", ~U[2024-01-01 00:00:00Z],
        username: "john",
        quote: "Previous message"
      )
  """
  def new(message_id, role, text, sent_at, options \\ []) do
    %__MODULE__{
      message_id: message_id,
      role: role,
      username: options[:username],
      text: text,
      sent_at: sent_at,
      reply: options[:reply],
      quote: options[:quote],
      user_id: options[:user_id],
      chat_id: options[:chat_id],
      image_url: options[:image_url]
    }
  end

  @impl AnyTalker.AI.Message.Behaviour
  def format_message(%__MODULE__{} = message) do
    %{
      role: message.role,
      content: build_content(message)
    }
  end

  defp build_content(%__MODULE__{role: :system, text: text}) do
    text
  end

  defp build_content(%__MODULE__{image_url: nil} = message) do
    build_json_content(message)
  end

  defp build_content(%__MODULE__{image_url: image_url} = message) do
    [
      %{type: "input_text", text: build_json_content(message)},
      %{type: "input_image", image_url: image_url}
    ]
  end

  defp build_json_content(message) do
    %{}
    |> maybe_add_text(message)
    |> maybe_add_username(message)
    |> maybe_add_quote(message)
    |> add_sent_at(message)
    |> Jason.encode!()
  end

  defp maybe_add_text(content, %__MODULE__{text: text}) when is_binary(text) do
    Map.put(content, :text, text)
  end

  defp maybe_add_text(content, _message), do: content

  defp maybe_add_username(content, %__MODULE__{role: :user, username: username}) when is_binary(username) do
    Map.put(content, :username, username)
  end

  defp maybe_add_username(content, _message), do: content

  defp maybe_add_quote(content, %__MODULE__{reply: %__MODULE__{quote: quote}}) when is_binary(quote) do
    Map.put(content, :quote, quote)
  end

  defp maybe_add_quote(content, _message), do: content

  defp add_sent_at(content, %__MODULE__{sent_at: sent_at}) do
    yekaterinburg_sent_at =
      sent_at
      |> DateTime.shift_zone!("Asia/Yekaterinburg")
      |> DateTime.truncate(:second)

    Map.put(content, :sent_at, DateTime.to_iso8601(yekaterinburg_sent_at))
  end
end
