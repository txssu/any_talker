defmodule AnyTalkerBot.Reply.Message do
  @moduledoc """
  A message action for Reply that sends text messages to Telegram.

  This module handles sending text messages with various options like parse mode,
  reply-to functionality, and DM forwarding.

  ## Fields

  - `text` - The message text to send
  - `mode` - Parse mode for the message (`:html`, `:markdown`, or `nil`)
  - `as_reply?` - Whether to reply to the original message
  - `for_dm` - Whether to send the message to the user's DM
  - `on_sent` - Callback function to run after the message is sent

  ## Example

      Reply.Message.new("Hello, world!")
      |> Map.put(:mode, :html)
      |> Map.put(:as_reply?, true)
  """

  @behaviour AnyTalkerBot.Reply.Action

  alias AnyTalkerBot.Reply
  alias AnyTalkerBot.Reply.Common
  alias ExGram.Model.Chat
  alias ExGram.Model.User

  require Logger

  defstruct text: nil,
            mode: nil,
            as_reply?: false,
            for_dm: false,
            on_sent: nil,
            reply_markup: nil,
            link_preview_options: nil

  @doc """
  Creates a new Message with the given text.

  ## Example

      Reply.Message.new("Hello")
  """
  def new(text) when is_binary(text) do
    %__MODULE__{text: text}
  end

  @impl Reply.Action
  def execute(%Reply{action: %__MODULE__{} = message} = reply) do
    message
    |> check_for_dm(reply)
    |> do_send(reply)
  end

  defp check_for_dm(%Reply.Message{for_dm: false} = message, %Reply{}), do: {:cont, message}

  defp check_for_dm(%Reply.Message{for_dm: true} = message, %Reply{} = reply) do
    if dm?(reply) do
      {:cont, message}
    else
      send_to_dm(message, reply)
    end
  end

  defp dm?(%Reply{} = reply) do
    %Chat{} = chat = Reply.chat(reply)
    chat.type == "private"
  end

  defp send_to_dm(%Reply.Message{} = message, %Reply{} = reply) do
    %User{} = user = Reply.user(reply)

    case send_message(message, reply, user.id) do
      {:ok, _sent_message} ->
        success_message = %Reply.Message{
          text: Common.dm_success_message(),
          mode: :html
        }

        {:cont, success_message}

      {:error, _reason} ->
        error_message = %Reply.Message{
          text: Common.dm_error_message(),
          mode: :html
        }

        {:cont, error_message}
    end
  end

  defp do_send({:cont, %Reply.Message{} = message}, %Reply{} = reply) do
    %Chat{} = chat = Reply.chat(reply)
    send_message(message, reply, chat.id)
  end

  defp send_message(%Reply.Message{} = message, %Reply{} = reply, chat_id) do
    case ExGram.send_message(chat_id, message.text, send_options(message, reply)) do
      {:ok, sent_message} ->
        run_callback(message, sent_message)
        {:ok, sent_message}

      {:error, error} when message.mode != nil ->
        Logger.error("Error sending message: #{inspect(error)}")
        Logger.warning("Retrying message without formatting")
        send_message(%{message | mode: nil}, reply, chat_id)

      {:error, error} ->
        Logger.error("Error sending message: #{inspect(error)}")
        {:error, error}
    end
  end

  defp run_callback(%Reply.Message{on_sent: nil}, _sent_message), do: :ok

  defp run_callback(%Reply.Message{on_sent: callback}, sent_message) when is_function(callback, 1) do
    callback.(sent_message)
  end

  defp send_options(%Reply.Message{} = message, %Reply{} = reply) do
    []
    |> Common.add_bot()
    |> Common.maybe_add_markdown(message.mode)
    |> Common.maybe_add_reply_to(reply, message.as_reply?)
    |> maybe_add_reply_markup(message.reply_markup)
    |> maybe_add_link_preview_options(message.link_preview_options)
  end

  defp maybe_add_reply_markup(opts, nil), do: opts
  defp maybe_add_reply_markup(opts, markup), do: [{:reply_markup, markup} | opts]

  defp maybe_add_link_preview_options(opts, nil), do: opts
  defp maybe_add_link_preview_options(opts, options), do: [{:link_preview_options, options} | opts]
end
