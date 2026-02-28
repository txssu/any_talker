defmodule AnyTalkerBot.Handlers.InlineQueryHandler do
  @moduledoc false

  alias AnyTalkerBot.Reply
  alias ExGram.Model.InlineQueryResultArticle
  alias ExGram.Model.InputTextMessageContent

  def execute(reply, {:inline_query, query}) do
    case query_type(query.query) do
      :empty -> send_combined_help(reply, query)
      :url -> AnyTalkerBot.EmbedLinkCommand.handle_inline_query(reply, query)
      :currency -> AnyTalkerBot.CurrencyCommand.handle_inline_query(reply, query)
      :ask -> AnyTalkerBot.InlineHandlers.AskInlineHandler.handle_inline_query(reply, query)
    end
  end

  def query_type(query_text) when is_binary(query_text) do
    case String.trim(query_text) do
      "" -> :empty
      trimmed -> classify(trimmed)
    end
  end

  defp classify(trimmed) do
    cond do
      String.contains?(trimmed, [".com", ".org", ".net", "http://", "https://"]) -> :url
      currency_format?(trimmed) -> :currency
      true -> :ask
    end
  end

  defp currency_format?(text) do
    case String.split(text, " ", trim: true) do
      [_from, _to, amount] ->
        expanded =
          amount
          |> String.downcase()
          |> String.replace("kk", "000000")
          |> String.replace("k", "000")

        match?({v, ""} when v > 0 and v <= 1_000_000_000, Float.parse(expanded))

      _other ->
        false
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
