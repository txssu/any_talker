defmodule AnyTalkerBot.Handlers.InlineQueryHandler do
  @moduledoc false

  alias AnyTalkerBot.Reply
  alias ExGram.Model.InlineQueryResultArticle
  alias ExGram.Model.InputTextMessageContent

  def execute(reply, {:inline_query, query}) do
    case detect_query_type(query.query) do
      :empty ->
        send_combined_help(reply, query)

      :url ->
        AnyTalkerBot.EmbedLinkCommand.handle_inline_query(reply, query)

      :currency ->
        AnyTalkerBot.CurrencyCommand.handle_inline_query(reply, query)
    end
  end

  defp detect_query_type(""), do: :empty

  defp detect_query_type(query_text) when is_binary(query_text) do
    trimmed = String.trim(query_text)

    cond do
      trimmed == "" ->
        :empty

      String.contains?(trimmed, [".com", ".org", ".net", "http://", "https://"]) ->
        :url

      true ->
        :currency
    end
  end

  defp send_combined_help(reply, query) do
    currency_help = %InlineQueryResultArticle{
      type: "article",
      id: "currency_help",
      title: "Конвертация валют",
      description: "Формат: {from} {to} {amount}",
      input_message_content: %InputTextMessageContent{
        message_text: "Формат: {from} {to} {amount}\nПоддерживаются сокращения: k (тысячи), kk (миллионы)"
      }
    }

    embed_help = %InlineQueryResultArticle{
      type: "article",
      id: "embed_help",
      title: "Встроенные ссылки",
      description: "Конвертация ссылок в embedded версии",
      input_message_content: %InputTextMessageContent{
        message_text: "Вставьте ссылку для создания embedded превью."
      }
    }

    Reply.answer_inline_query(reply, query.id, [currency_help, embed_help])
  end
end
