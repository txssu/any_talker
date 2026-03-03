defmodule AnyTalkerBot.InlineHandlers.CurrencyInlineHandler do
  @moduledoc false

  @behaviour AnyTalkerBot.InlineHandler

  alias AnyTalker.Currency.Client
  alias ExGram.Model.InlineQueryResultArticle
  alias ExGram.Model.InputTextMessageContent

  @impl AnyTalkerBot.InlineHandler
  def match?(query_text) do
    case String.split(query_text, " ", trim: true) do
      [_from, _to, amount_str] -> valid_amount?(amount_str)
      _other -> false
    end
  end

  @impl AnyTalkerBot.InlineHandler
  def build_results(query) do
    case parse_query(query.query) do
      {:ok, from, to, amount} -> build_conversion_results(from, to, amount)
      {:error, :invalid_format} -> [help_result()]
    end
  end

  defp valid_amount?(amount_str) do
    expanded = expand_shortcuts(amount_str)

    case Float.parse(expanded) do
      {v, ""} when v > 0 and v <= 1_000_000_000 -> true
      _other -> false
    end
  end

  defp parse_query(query_text) do
    case String.split(query_text, " ", trim: true) do
      [from, to, amount_str] ->
        case parse_amount(amount_str) do
          {:ok, amount} -> {:ok, String.downcase(from), String.downcase(to), amount}
          :error -> {:error, :invalid_format}
        end

      _other ->
        {:error, :invalid_format}
    end
  end

  defp parse_amount(amount_str) do
    expanded = expand_shortcuts(amount_str)

    case Float.parse(expanded) do
      {amount, ""} when amount > 0 and amount <= 1_000_000_000 -> {:ok, amount}
      _other -> :error
    end
  end

  defp expand_shortcuts(amount_str) do
    amount_str
    |> String.downcase()
    |> String.replace("kk", "000000")
    |> String.replace("k", "000")
  end

  defp build_conversion_results(from, to, amount) do
    case Client.get_currencies(from) do
      {:ok, rates} ->
        case Map.get(rates, to) do
          nil -> [error_result("Валюта '#{to}' не найдена для '#{from}'")]
          rate -> [conversion_result(from, to, amount, amount * rate)]
        end

      {:error, :not_found} ->
        [error_result("Валюта '#{from}' не найдена")]

      {:error, _reason} ->
        [error_result("Ошибка получения курса валют")]
    end
  end

  defp conversion_result(from, to, amount, converted_amount) do
    from_formatted = format_amount(amount, from)
    to_formatted = format_amount(converted_amount, to)

    %InlineQueryResultArticle{
      type: "article",
      id: "currency_conversion",
      title: "#{String.upcase(from)} → #{String.upcase(to)}",
      description: "#{from_formatted} → #{to_formatted}",
      input_message_content: %InputTextMessageContent{
        message_text: "#{from_formatted}\n#{to_formatted}"
      }
    }
  end

  defp error_result(message) do
    %InlineQueryResultArticle{
      type: "article",
      id: "currency_error",
      title: "Ошибка",
      description: message,
      input_message_content: %InputTextMessageContent{message_text: message}
    }
  end

  defp help_result do
    help_text = "Формат: {from} {to} {amount}\nПоддерживаются сокращения: k (тысячи), kk (миллионы)"

    %InlineQueryResultArticle{
      type: "article",
      id: "currency_help",
      title: "Конвертация валют",
      description: help_text,
      input_message_content: %InputTextMessageContent{message_text: help_text}
    }
  end

  defp format_amount(amount, currency_code) do
    AnyTalker.Cldr.Number.to_string!(amount,
      currency: String.upcase(currency_code),
      currency_digits: :cash,
      currency_symbol: :symbol
    )
  end
end
