defmodule AnyTalkerBot.RssPaginationHandler do
  @moduledoc false

  use AnyTalkerBot, :command

  alias AnyTalker.RSS
  alias AnyTalkerBot.Reply
  alias AnyTalkerBot.RssFormatter

  require Logger

  @impl AnyTalkerBot.Command
  def call(%Reply{} = reply) do
    callback_query = Reply.callback_query(reply)
    {page, group_id_or_nil} = parse_callback_data(callback_query.data)
    user_id = callback_query.from.id
    chat_id = callback_query.message.chat.id
    message_id = callback_query.message.message_id

    {articles, total} = RSS.list_articles(user_id, group_id_or_nil, page)
    {text, keyboard} = RssFormatter.format_news_page(articles, page, total, group_id_or_nil)

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
      Logger.error("RssPaginationHandler failed: #{inspect(error)}\n#{Exception.format_stacktrace(__STACKTRACE__)}")
      Reply.answer_callback_query(reply, Reply.callback_query(reply).id)
  end

  defp parse_callback_data("rss_news:" <> rest) do
    case String.split(rest, ":", parts: 2) do
      [page_str, group_str] -> {String.to_integer(page_str), parse_group(group_str)}
      [page_str] -> {String.to_integer(page_str), nil}
    end
  end

  defp parse_group("0"), do: nil
  defp parse_group(id), do: String.to_integer(id)
end
