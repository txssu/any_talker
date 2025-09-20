defmodule AnyTalkerBot.CurrencyCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.Currency.Client
  alias AnyTalkerBot.Reply

  @impl AnyTalkerBot.Command
  def call(%Reply{message: {:command, :curs, message}} = reply) do
    case parse_command_args(message.text) do
      {:ok, from, to, amount} ->
        handle_currency_conversion(reply, from, to, amount)

      {:error, :invalid_format} ->
        %{
          reply
          | text:
              "Использование: /curs {from} {to} {amount}\nПример: /curs usd rub 100\nПоддерживаются сокращения: k (тысячи), kk (миллионы)\nМаксимум: 1 миллиард"
        }
    end
  end

  defp parse_command_args(text) do
    case String.split(text, " ", trim: true) do
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

  defp handle_currency_conversion(reply, from, to, amount) do
    case Client.get_currencies(from) do
      {:ok, rates} ->
        case Map.get(rates, to) do
          nil ->
            %{reply | text: "Валюта '#{to}' не найдена для '#{from}'"}

          rate ->
            converted_amount = amount * rate

            format_currency_response(reply, from, to, amount, converted_amount)
        end

      {:error, :not_found} ->
        %{reply | text: "Валюта '#{from}' не найдена"}

      {:error, _reason} ->
        %{reply | text: "Ошибка получения курса валют"}
    end
  end

  defp format_currency_response(reply, from, to, amount, converted_amount) do
    from_formatted = format_amount(amount, from)
    to_formatted = format_amount(converted_amount, to)

    text = """
    #{from_formatted}
    #{to_formatted}
    """

    %{reply | text: text}
  end

  defp format_amount(amount, currency_code) do
    AnyTalker.Cldr.Number.to_string!(amount,
      currency: String.upcase(currency_code),
      currency_digits: :cash,
      currency_symbol: :symbol
    )
  end
end
