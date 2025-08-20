defmodule AnyTalker.AI.Message do
  @moduledoc false
  use TypedStruct

  @type role :: :assistant | :system | :user

  typedstruct do
    field :message_id, integer() | nil
    field :chat_id, integer() | nil
    field :user_id, integer() | nil

    field :role, role()
    field :username, String.t() | nil
    field :text, String.t()

    field :reply, t() | nil
    field :quote, String.t() | nil

    field :image_url, String.t() | nil
  end

  @spec new(integer(), role(), String.t(), keyword()) :: t()
  def new(message_id, role, text, options \\ []) do
    %__MODULE__{
      message_id: message_id,
      role: role,
      username: options[:username],
      text: text,
      reply: options[:reply],
      quote: options[:quote],
      user_id: options[:user_id],
      chat_id: options[:chat_id],
      image_url: options[:image_url]
    }
  end

  @spec format_list([t()]) :: [%{role: :user | :system | :assistant, content: String.t()}]
  def format_list(messages) do
    messages
    |> Enum.sort_by(& &1.message_id)
    |> Enum.flat_map(&format_message(&1, get_message_ids(messages)))
  end

  @spec format_message(t(), [integer()]) :: [%{role: :user | :system | :assistant, content: String.t()}]
  def format_message(message, messages_ids) do
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

  defp append(list, elem) do
    [elem | list]
  end
end
