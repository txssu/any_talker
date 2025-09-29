defmodule AnyTalkerBot.Reply2.Message do
  @moduledoc """
  A message action for Reply2 that sends text messages to Telegram.

  This module handles sending text messages with various options like parse mode,
  reply-to functionality, and DM forwarding.

  ## Fields

  - `text` - The message text to send
  - `mode` - Parse mode for the message (`:html`, `:markdown`, or `nil`)
  - `as_reply?` - Whether to reply to the original message
  - `for_dm` - Whether to send the message to the user's DM
  - `on_sent` - Callback function to run after the message is sent

  ## Example

      Reply2.Message.new("Hello, world!")
      |> Map.put(:mode, :html)
      |> Map.put(:as_reply?, true)
  """

  @behaviour AnyTalkerBot.Reply2.Action

  import AnyTalkerBot.MarkdownUtils

  alias AnyTalkerBot.Reply2

  require Logger

  defstruct text: nil,
            mode: nil,
            as_reply?: false,
            for_dm: false,
            on_sent: nil

  @doc """
  Creates a new Message with the given text.

  ## Example

      Reply2.Message.new("Hello")
  """
  def new(text) when is_binary(text) do
    %__MODULE__{text: text}
  end

  @impl Reply2.Action
  def execute(%Reply2{action: %__MODULE__{} = message} = reply) do
    message
    |> check_for_dm(reply)
    |> do_send(reply)
  end

  defp check_for_dm(%Reply2.Message{for_dm: false} = message, %Reply2{}), do: {:cont, message}

  defp check_for_dm(%Reply2.Message{for_dm: true} = message, %Reply2{} = reply) do
    if dm?(reply) do
      {:cont, message}
    else
      send_to_dm(message, reply)
    end
  end

  defp dm?(%Reply2{context: context}) do
    context.update.message.chat.type == "private"
  end

  defp send_to_dm(%Reply2.Message{} = message, %Reply2{} = reply) do
    user_id = reply.context.update.message.from.id

    case send_message(message, reply, user_id) do
      {:ok, _sent_message} ->
        success_message = %Reply2.Message{
          text: dm_success_message(),
          mode: :html
        }

        {:cont, success_message}

      {:error, _reason} ->
        error_message = %Reply2.Message{
          text: dm_error_message(),
          mode: :html
        }

        {:cont, error_message}
    end
  end

  defp do_send({:cont, %Reply2.Message{} = message}, %Reply2{} = reply) do
    chat_id = reply.context.update.message.chat.id
    send_message(message, reply, chat_id)
  end

  defp send_message(%Reply2.Message{} = message, %Reply2{} = reply, chat_id) do
    case ExGram.send_message(chat_id, message.text, send_options(message, reply)) do
      {:ok, sent_message} ->
        AnyTalker.Events.save_new_message(sent_message)
        run_callback(message, sent_message)
        {:ok, sent_message}

      {:error, error} ->
        Logger.error("Error sending message: #{inspect(error)}")
        {:error, error}
    end
  end

  defp run_callback(%Reply2.Message{on_sent: nil}, _sent_message), do: :ok

  defp run_callback(%Reply2.Message{on_sent: callback}, sent_message) when is_function(callback, 1) do
    callback.(sent_message)
  end

  defp send_options(%Reply2.Message{} = message, %Reply2{} = reply) do
    []
    |> add_bot()
    |> maybe_add_markdown(message)
    |> maybe_add_reply_to(message, reply)
  end

  defp add_bot(options), do: [{:bot, AnyTalkerBot.bot()} | options]

  defp maybe_add_markdown(options, %Reply2.Message{mode: nil}), do: options
  defp maybe_add_markdown(options, %Reply2.Message{mode: :html}), do: [{:parse_mode, "HTML"} | options]
  defp maybe_add_markdown(options, %Reply2.Message{mode: :markdown}), do: [{:parse_mode, "MarkdownV2"} | options]

  defp maybe_add_reply_to(options, %Reply2.Message{} = message, %Reply2{} = reply) do
    if reply.context.update.message.chat.type != "private" or message.as_reply? do
      original_message = reply.context.update.message

      reply_to = %ExGram.Model.ReplyParameters{
        message_id: original_message.message_id,
        chat_id: original_message.chat.id
      }

      [{:reply_parameters, reply_to} | options]
    else
      options
    end
  end

  defp dm_success_message do
    "Ответ отправлен в личные сообщения."
  end

  defp dm_error_message do
    ~i"Не удалось отправить сообщение в личные сообщения\. Пожалуйста, разблокируйте бота и начните с ним диалог командой /start\."
  end
end
