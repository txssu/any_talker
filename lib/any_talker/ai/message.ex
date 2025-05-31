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

  @spec format_message(t(), [integer()]) :: [%{role: :user | :system | :assistant, content: String.t()}]
  def format_message(message, messages_ids) do
    []
    |> maybe_append_reply(message, messages_ids)
    |> maybe_append_quote(message)
    |> maybe_append_username(message)
    |> append_content(message)
    |> Enum.reverse()
  end

  defp maybe_append_reply(result, message, messages_ids) do
    reply = message.reply

    if reply && reply.message_id not in messages_ids do
      result
      |> maybe_append_username(reply)
      |> append_content(reply)
    else
      result
    end
  end

  defp maybe_append_quote(result, message) do
    if message.reply && message.reply.quote do
      append(result, %{role: :system, content: quote_message_content(message.reply)})
    else
      result
    end
  end

  defp maybe_append_username(result, message) do
    case message.role do
      :user -> append(result, %{role: :system, content: username_message_content(message)})
      _other -> result
    end
  end

  defp append_content(result, message) do
    append(result, %{role: message.role, content: build_content(message)})
  end

  defp build_content(message) do
    []
    |> build_content_text(message)
    |> build_content_image(message)
    |> Enum.reverse()
  end

  defp build_content_text(content, %__MODULE__{text: nil}), do: content
  defp build_content_text(content, %__MODULE__{text: t}), do: append(content, %{type: "input_text", text: t})

  defp build_content_image(content, %__MODULE__{image_url: nil}), do: content

  defp build_content_image(content, %__MODULE__{image_url: u}),
    do: append(content, %{type: "input_image", image_url: u})

  defp append(list, elem) do
    [elem | list]
  end

  defp username_message_content(message) do
    safe_username = safe_text(message.username)
    ~s(Next message author's username:\n"""\n#{safe_username}\n""")
  end

  defp quote_message_content(message) do
    safe_quote = safe_text(message.quote)
    ~s(Quoted text from the previous message:\n"""\n#{safe_quote}\n""")
  end

  defp safe_text(text) do
    String.replace(text, ~s("), "")
  end
end
