defmodule AnyTalker.AI.Tool do
  @moduledoc false
  alias AnyTalker.AI.FunctionContext
  alias AnyTalker.AI.Response.ToolCall
  alias AnyTalker.AI.Tool.CallResult
  alias AnyTalker.AI.Tool.Registry

  require Logger

  @callback spec() :: AnyTalker.AI.Tool.Function.t()
  @callback call(map(), FunctionContext.t()) :: term()

  @continue_text """
  Достигнут лимит вызовов (2 за ход).
  Перестань вызывать инструменты, расскажи пользователю что уже сделано,
  и попроси его написать "продолжай" чтобы ты мог завершить задачу.
  """

  def execute(%ToolCall{} = tool_call, %FunctionContext{} = context, call_index) do
    Logger.info("Executing tool",
      details: %{id: tool_call.tool_call_id, function_name: tool_call.function_name, params: tool_call.arguments}
    )

    {returned_value, module} =
      if call_index < 2 do
        module = Registry.get_module_by_func_name(tool_call.function_name)

        {module.call(tool_call.arguments, context), module}
      else
        {{:error, @continue_text}, nil}
      end

    returned_value
    |> CallResult.new(tool_call, module)
    |> with_call_result_log(tool_call)
  end

  def with_call_result_log(%CallResult{} = call_result, %ToolCall{} = tool_call) do
    result =
      if call_result.success do
        %{value: call_result.value}
      else
        %{error: call_result.error}
      end

    Logger.info("Executing tool result",
      details: Map.merge(result, %{id: tool_call.tool_call_id, success: call_result.success})
    )

    call_result
  end
end
