defmodule AnyTalkerBot.InlineHandlers.CleanUrlInlineHandler do
  @moduledoc false

  @behaviour AnyTalkerBot.InlineHandler

  alias AnyTalker.ClearUrl
  alias AnyTalkerBot.HtmlUtils
  alias ExGram.Model.InlineQueryResultArticle
  alias ExGram.Model.InputTextMessageContent

  @url_regex ~r/https?:\/\/[^\s<>"')\]]+/

  @impl AnyTalkerBot.InlineHandler
  def match?(query_text), do: Regex.match?(@url_regex, query_text)

  @impl AnyTalkerBot.InlineHandler
  def build_results(query) do
    text = String.trim(query.query)

    cleaned_text =
      Regex.replace(@url_regex, text, fn url ->
        ClearUrl.clean(url)
      end)

    escaped_text = HtmlUtils.escape_html(cleaned_text)

    [
      %InlineQueryResultArticle{
        type: "article",
        id: "clean_url",
        title: "Убрать трекеры из ссылок",
        description: String.slice(cleaned_text, 0, 100),
        input_message_content: %InputTextMessageContent{
          message_text: "Вот текст без трекеров\n<blockquote>#{escaped_text}</blockquote>",
          parse_mode: "HTML"
        }
      }
    ]
  end
end
