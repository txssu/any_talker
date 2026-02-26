defmodule AnyTalkerBot.Reply.Common do
  @moduledoc """
  Common utility functions shared across Reply action modules.
  """

  alias AnyTalkerBot.Reply
  alias ExGram.Model.Chat
  alias ExGram.Model.Message

  @doc """
  Adds bot to options.
  """
  def add_bot(options), do: [{:bot, AnyTalkerBot.Dispatcher.bot()} | options]

  @doc """
  Adds parse_mode to options if mode is specified.
  """
  def maybe_add_markdown(options, nil), do: options
  def maybe_add_markdown(options, :html), do: [{:parse_mode, "HTML"} | options]
  def maybe_add_markdown(options, :markdown), do: [{:parse_mode, "MarkdownV2"} | options]

  @doc """
  Adds reply_parameters to options if appropriate.
  """
  def maybe_add_reply_to(options, %Reply{} = reply, as_reply? \\ false) do
    %Message{} = message = Reply.message(reply)
    %Chat{} = chat = Reply.chat(reply)

    if chat.type != "private" or as_reply? do
      reply_to = %ExGram.Model.ReplyParameters{
        message_id: message.message_id,
        chat_id: chat.id
      }

      [{:reply_parameters, reply_to} | options]
    else
      options
    end
  end

  @doc """
  Returns success message for DM sending.
  """
  def dm_success_message do
    "Ответ отправлен в личные сообщения."
  end

  @doc """
  Returns error message for DM sending.
  """
  def dm_error_message do
    "Не удалось отправить сообщение в личные сообщения. Пожалуйста, разблокируйте бота и начните с ним диалог командой /start."
  end
end
