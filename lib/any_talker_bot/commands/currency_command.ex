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
    from_formatted = format_amount(amount)
    to_formatted = format_amount(converted_amount)

    text = """
    #{String.upcase(from)}: #{from_formatted}
    #{String.upcase(to)}: #{to_formatted}
    """

    %{reply | text: text}
  end

  defp format_amount(amount) when is_float(amount) do
    amount
    |> :erlang.float_to_binary(decimals: 2)
    |> add_thousands_separator()
  end

  defp add_thousands_separator(amount_str) do
    [integer_part, decimal_part] = String.split(amount_str, ".")

    formatted_integer =
      integer_part
      |> String.reverse()
      |> String.graphemes()
      |> Enum.chunk_every(3)
      |> Enum.map_join("\u202F", &Enum.join/1)
      |> String.reverse()

    if decimal_part == "00" do
      formatted_integer
    else
      "#{formatted_integer}.#{decimal_part}"
    end
  end
end
