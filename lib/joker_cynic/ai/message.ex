defmodule JokerCynic.AI.Message do
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
      chat_id: options[:chat_id]
    }
  end

  @spec prompt_message(String.t()) :: t()
  def prompt_message(text) do
    %__MODULE__{
      role: :system,
      text: text
    }
  end

  @spec format_list([t()]) :: [%{role: role, content: String.t()}]
  def format_list(messages) when is_list(messages) do
    messages_ids = Enum.map(messages, & &1.message_id)

    messages
    |> Enum.flat_map(&format_message(&1, messages_ids))
    |> Enum.reverse()
  end

  defp format_message(message, messages_ids) do
    []
    |> maybe_append_reply(message, messages_ids)
    |> maybe_append_quote(message)
    |> maybe_append_username(message)
    |> append_text(message)
  end

  defp maybe_append_reply(result, message, messages_ids) do
    reply = message.reply

    if reply && reply.message_id not in messages_ids do
      result
      |> maybe_append_username(reply)
      |> append_text(reply)
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

  defp append_text(result, message) do
    append(result, %{role: message.role, content: message.text})
  end

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
