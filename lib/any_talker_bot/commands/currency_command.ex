defmodule AnyTalkerBot.CurrencyCommand do
  @moduledoc false

  alias AnyTalker.Currency.Client
  alias ExGram.Model.InlineQueryResultArticle
  alias ExGram.Model.InputTextMessageContent

  def handle_inline_query(reply, query) do
    case parse_inline_query(query.query) do
      {:ok, from, to, amount} ->
        handle_inline_conversion(reply, query, from, to, amount)

      {:error, :invalid_format} ->
        send_inline_help(reply, query)
    end
  end

  defp parse_inline_query(query_text) do
    case String.split(query_text, " ", trim: true) do
      [from, to, amount_str] ->
        case parse_amount(amount_str) do
          {:ok, amount} -> {:ok, String.downcase(from), String.downcase(to), amount}
          :error -> {:error, :invalid_format}
        end

      _otherwise ->
        {:error, :invalid_format}
    end
  end

  defp parse_amount(amount_str) do
    amount_str
    |> expand_shortcuts()
    |> parse_float()
    |> validate_amount()
  end

  defp expand_shortcuts(amount_str) do
    amount_str
    |> String.downcase()
    |> String.replace("kk", "000000")
    |> String.replace("k", "000")
  end

  defp parse_float(amount_str) do
    case Float.parse(amount_str) do
      {amount, ""} when amount > 0 -> {:ok, amount}
      _otherwise -> :error
    end
  end

  defp validate_amount({:ok, amount}) when amount > 1_000_000_000, do: :error
  defp validate_amount(result), do: result

  defp handle_inline_conversion(reply, query, from, to, amount) do
    case Client.get_currencies(from) do
      {:ok, rates} ->
        case Map.get(rates, to) do
          nil ->
            send_inline_error(reply, query, "Валюта '#{to}' не найдена для '#{from}'")

          rate ->
            converted_amount = amount * rate
            send_inline_result(reply, query, from, to, amount, converted_amount)
        end

      {:error, :not_found} ->
        send_inline_error(reply, query, "Валюта '#{from}' не найдена")

      {:error, _reason} ->
        send_inline_error(reply, query, "Ошибка получения курса валют")
    end
  end

  defp send_inline_result(reply, query, from, to, amount, converted_amount) do
    from_formatted = format_amount(amount, from)
    to_formatted = format_amount(converted_amount, to)

    result_text = """
    #{from_formatted}
    #{to_formatted}
    """

    result = %InlineQueryResultArticle{
      type: "article",
      id: "currency_conversion",
      title: "#{String.upcase(from)} → #{String.upcase(to)}",
      description: "#{from_formatted} → #{to_formatted}",
      input_message_content: %InputTextMessageContent{
        message_text: result_text
      }
    }

    ExGram.answer_inline_query(query.id, [result], bot: AnyTalkerBot.Dispatcher.bot())
    %{reply | halt: true}
  end

  defp send_inline_error(reply, query, error_message) do
    result = %InlineQueryResultArticle{
      type: "article",
      id: "currency_error",
      title: "Ошибка",
      description: error_message,
      input_message_content: %InputTextMessageContent{
        message_text: error_message
      }
    }

    ExGram.answer_inline_query(query.id, [result], bot: AnyTalkerBot.Dispatcher.bot())
    %{reply | halt: true}
  end

  defp send_inline_help(reply, query) do
    help_text =
      "Формат: {from} {to} {amount}\nПоддерживаются сокращения: k (тысячи), kk (миллионы)"

    result = %InlineQueryResultArticle{
      type: "article",
      id: "currency_help",
      title: "Конвертация валют",
      description: help_text,
      input_message_content: %InputTextMessageContent{
        message_text: help_text
      }
    }

    ExGram.answer_inline_query(query.id, [result], bot: AnyTalkerBot.Dispatcher.bot())
    %{reply | halt: true}
  end

  defp format_amount(amount, currency_code) do
    AnyTalker.Cldr.Number.to_string!(amount,
      currency: String.upcase(currency_code),
      currency_digits: :cash,
      currency_symbol: :symbol
    )
  end
end
