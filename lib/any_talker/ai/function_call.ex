defmodule AnyTalker.AI.FunctionCall do
  @moduledoc false

  alias AnyTalker.AI.Context
  alias AnyTalker.AI.Message.FunctionToolCallOutput
  alias AnyTalker.AI.ToolsRegistry
  alias AnyTalker.Parser

  defstruct module: nil, arguments: nil, call_id: nil, name: nil, arguments_json: nil, id: nil

  def parse(params) do
    parsers = %{
      module: &parse_module/1,
      arguments: &parse_arguments/1,
      call_id: Parser.not_nil_parser(& &1["call_id"], "function_call.call_id not found"),
      name: Parser.not_nil_parser(& &1["name"], "function_call.name not found"),
      arguments_json: Parser.not_nil_parser(& &1["arguments"], "function_call.arguments not found"),
      id: Parser.optional_parser(& &1["id"])
    }

    Parser.parse(%__MODULE__{}, params, parsers)
  end

  def exec(%__MODULE__{module: module, arguments: params, call_id: call_id}, %Context{} = context) do
    call_result = module.exec(params, context)

    FunctionToolCallOutput.new(call_id, Jason.encode!(call_result))
  end

  defp parse_module(function_call) do
    with {:ok, name} <- Parser.not_nil(function_call["name"], "function_call.name not found") do
      ToolsRegistry.get_function_module_by_name(name)
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
