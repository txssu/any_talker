defmodule AnyTalker.Parser do
  @moduledoc false
  defstruct to: nil, valid?: true, invalid_reason: nil, raw: nil

  def parse(model, params, parsers) do
    parsing = %__MODULE__{to: model, raw: params}

    result =
      Enum.reduce(parsers, parsing, fn {key, parser}, result ->
        parse_with(result, key, parser)
      end)

    if result.valid? do
      {:ok, result.to}
    else
      {:error, params}
    end
  end

  defp parse_with(%__MODULE__{valid?: false} = parsing, _key, _cast_function), do: parsing

  defp parse_with(%__MODULE__{raw: raw} = parsing, key, parse_function) do
    case parse_function.(raw) do
      {:ok, value} -> %{parsing | to: Map.put(parsing.to, key, value)}
      {:error, reason} -> %{parsing | invalid_reason: reason, valid?: false}
    end
  end

  def not_nil_parser(accesser, msg) do
    fn data ->
      data
      |> accesser.()
      |> not_nil(msg)
    end
  end

  def optional_parser(accesser) do
    fn data ->
      {:ok, accesser.(data)}
    end
  end

  def not_nil(nil, msg), do: {:error, msg}
  def not_nil(value, _msg), do: {:ok, value}
end
