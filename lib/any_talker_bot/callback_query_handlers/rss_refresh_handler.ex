defmodule AnyTalkerBot.RssRefreshHandler do
  @moduledoc false

  use AnyTalkerBot, :command

  alias AnyTalker.RSS
  alias AnyTalkerBot.Reply
  alias AnyTalkerBot.RssFormatter

  require Logger

  @impl AnyTalkerBot.Command
  def call(%Reply{} = reply) do
    callback_query = Reply.callback_query(reply)
    group_id = parse_callback_data(callback_query.data)
    user_id = callback_query.from.id
    chat_id = callback_query.message.chat.id
    message_id = callback_query.message.message_id

    {articles, total} = RSS.list_articles(user_id, group_id, 0)
    {text, keyboard} = RssFormatter.format_news_page(articles, 0, total, group_id)

    ExGram.edit_message_text(text,
      chat_id: chat_id,
      message_id: message_id,
      bot: AnyTalkerBot.bot(),
      parse_mode: "HTML",
      reply_markup: keyboard,
      link_preview_options: %ExGram.Model.LinkPreviewOptions{is_disabled: true}
    )

    Reply.answer_callback_query(reply, callback_query.id)
  rescue
    error ->
      Logger.error("RssRefreshHandler failed: #{inspect(error)}\n#{Exception.format_stacktrace(__STACKTRACE__)}")
      Reply.answer_callback_query(reply, Reply.callback_query(reply).id)
  end

  defp parse_callback_data("rss_refresh:" <> group_str), do: parse_group(group_str)

  defp parse_group("0"), do: nil
  defp parse_group(id), do: String.to_integer(id)
end
