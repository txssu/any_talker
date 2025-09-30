defmodule AnyTalkerBot.Reply.Common do
  @moduledoc """
  Common utility functions shared across Reply action modules.
  """

  alias AnyTalkerBot.Reply

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
    if reply.context.update.message.chat.type != "private" or as_reply? do
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
