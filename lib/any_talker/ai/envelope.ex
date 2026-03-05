defmodule AnyTalker.AI.Envelope do
  @moduledoc false
  alias AnyTalker.AI.FunctionContext
  alias AnyTalker.AI.History.Key
  alias AnyTalker.TypedStructAccess

  require TypedStructAccess

  defstruct [
    :message_id,
    :role,
    :username,
    :text,
    :image_base64,
    :quote,
    :reply,
    :instructions,
    :models,
    # Metadata
    :chat,
    :author,
    :message
  ]

  @type t :: %__MODULE__{}

  def messages(%__MODULE__{} = envelope) do
    reply_messages =
      if envelope.reply do
        messages(envelope.reply)
      else
        []
      end

    message_id = TypedStructAccess.get(envelope.message.message_id, [ExGram.Model.Message])

    text = json_text(envelope)

    this_messages =
      if is_nil(text) and is_nil(envelope.image_base64) do
        []
      else
        [AnyTalker.AI.Message.new(message_id, envelope.role, text, envelope.image_base64)]
      end

    reply_messages ++ this_messages
  end

  def instructions(%__MODULE__{} = envelope) do
    AnyTalker.AI.Message.new(nil, "system", envelope.instructions, nil)
  end

  def function_context(%__MODULE__{} = envelope) do
    %FunctionContext{chat: envelope.chat, user: envelope.author, message: envelope.message, text: envelope.text}
  end

  defp json_text(%__MODULE__{} = envelope) do
    if envelope.text in [nil, ""] do
      nil
    else
      []
      |> put(:username, envelope.username)
      |> put_not_nil(:quote, envelope.quote)
      |> put(:text, envelope.text)
      |> Enum.reverse()
      |> Jason.OrderedObject.new()
      |> Jason.encode!()
    end
  end

  defp put_not_nil(list, _key, nil), do: list
  defp put_not_nil(list, key, value), do: put(list, key, value)

  defp put(list, key, value), do: [{key, value} | list]

  defimpl AnyTalker.AI.History.Storable do
    alias AnyTalker.AI.Envelope
    alias AnyTalker.Settings.ChatConfig

    require TypedStructAccess

    def to_key(%Envelope{} = envelope) do
      case envelope.reply do
        nil ->
          Key.new()

        %Envelope{} = reply ->
          chat_id = TypedStructAccess.get(reply.chat.id, [ChatConfig])
          Key.new(chat_id, reply.message_id)
      end
    end
  end
end
