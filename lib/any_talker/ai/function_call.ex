defmodule AnyTalker.AI.FunctionCall do
  @moduledoc false

  alias AnyTalker.Ai.FunctionsRegistry
  alias AnyTalker.Parser

  defstruct module: nil, arguments: nil, call_id: nil

  def parse(params) do
    parsers = %{
      module: &parse_module/1,
      arguments: &parse_arguments/1,
      call_id: Parser.not_nil_parser(& &1["call_id"], "function_call.call_id not found")
    }

    Parser.parse(%__MODULE__{}, params, parsers)
  end

  def exec(%__MODULE__{module: module, arguments: params, call_id: call_id}, extra) do
    call_result = module.exec(params, extra)

    %{
      type: "function_call_output",
      call_id: call_id,
      output: Jason.encode!(call_result)
    }
  end

  defp parse_module(function_call) do
    with {:ok, name} <- Parser.not_nil(function_call["name"], "function_call.name not found") do
      FunctionsRegistry.get_module_by_name(name)
    end
  end

  defp parse_arguments(function_call) do
    with {:ok, name} <- Parser.not_nil(function_call["arguments"], "function_call.arguments not found") do
      decode_json(name)
    end
  end

  def decode_json(data) do
    with {:error, _error} <- Jason.decode(data) do
      :error
    end
  end
end
