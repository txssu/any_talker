defmodule AnyTalkerBot.RssMarkReadHandler do
  @moduledoc false

  use AnyTalkerBot, :command

  alias AnyTalker.RSS
  alias AnyTalkerBot.Reply

  require Logger

  @impl AnyTalkerBot.Command
  def call(%Reply{} = reply) do
    callback_query = Reply.callback_query(reply)
    group_id = parse_callback_data(callback_query.data)
    user_id = callback_query.from.id
    chat_id = callback_query.message.chat.id
    message_id = callback_query.message.message_id

    RSS.mark_all_read(user_id, group_id)

    ExGram.edit_message_reply_markup(
      chat_id: chat_id,
      message_id: message_id,
      bot: AnyTalkerBot.bot(),
      reply_markup: %ExGram.Model.InlineKeyboardMarkup{inline_keyboard: []}
    )

    Reply.answer_callback_query(reply, callback_query.id, text: "Отмечено как прочитанное")
  rescue
    error ->
      Logger.error("RssMarkReadHandler failed: #{inspect(error)}\n#{Exception.format_stacktrace(__STACKTRACE__)}")
      Reply.answer_callback_query(reply, Reply.callback_query(reply).id)
  end

  defp parse_callback_data("rss_read:" <> group_str), do: parse_group(group_str)

  defp parse_group("0"), do: nil
  defp parse_group(id), do: String.to_integer(id)
end
