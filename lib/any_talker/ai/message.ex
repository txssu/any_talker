defmodule AnyTalker.AI.Message do
  @moduledoc false

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

  def format_list(messages) do
    messages
    |> Enum.sort_by(& &1.message_id)
    |> Enum.flat_map(&format_message(&1, get_message_ids(messages)))
  end

  def format_message(%__MODULE__{} = message, messages_ids) do
    []
    |> maybe_append_reply(message, messages_ids)
    |> append_content(message)
    |> Enum.reverse()
  end

  defp get_message_ids(messages) do
    Enum.map(messages, & &1.message_id)
  end

  defp maybe_append_reply(result, message, messages_ids) do
    reply = message.reply

    if reply && reply.message_id not in messages_ids do
      append_content(result, reply)
    else
      result
    end
  end

  defp append_content(result, message) do
    # Always use JSON, but handle images as separate content blocks
    content = build_json_and_attachments(message)
    append(result, %{role: message.role, content: content})
  end

  defp build_json_and_attachments(message) do
    # Build JSON content with all text data
    json_content = build_json_content(message)

    # Add attachments if present
    case message.image_url do
      nil ->
        json_content

      image_url ->
        [
          %{type: "input_text", text: json_content},
          %{type: "input_image", image_url: image_url}
        ]
    end
  end

  defp build_json_content(message) do
    content_map =
      %{}
      |> maybe_add_text(message)
      |> maybe_add_username(message)
      |> maybe_add_quote(message)
      |> add_sent_at(message)

    Jason.encode!(content_map)
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
    yekaterinburg_sent_at = DateTime.shift_zone!(sent_at, "Asia/Yekaterinburg")
    Map.put(content, :sent_at, DateTime.to_iso8601(yekaterinburg_sent_at))
  end

  defp append(list, elem) do
    [elem | list]
  end
end
