defmodule AnyTalker.AI.Tool.CallResult do
  @moduledoc false
  alias __MODULE__
  alias AnyTalker.AI.Content.Text
  alias AnyTalker.AI.Response.ToolCall

  defstruct [:success, :value, :error, :tool_call, :module]

  def new({_res, _data} = tuple, %ToolCall{} = tool_call, module) do
    %__MODULE__{} = result = from_tuple(tuple)
    %{result | tool_call: tool_call, module: module}
  end

  def to_content(%__MODULE__{success: true, value: value}) do
    do_to_content(success: true, value: value)
  end

  def to_content(%__MODULE__{success: false, error: error}) do
    do_to_content(success: false, error: error)
  end

  defp do_to_content(data) do
    data
    |> Jason.OrderedObject.new()
    |> Jason.encode!()
    |> Text.new()
    |> List.wrap()
  end

  defp from_tuple({:ok, value}) do
    %__MODULE__{success: true, value: value}
  end

  defp from_tuple({:error, error_msg}) do
    %__MODULE__{success: false, error: error_msg}
  end

  defimpl AnyTalker.AI.ToMessage do
    def to_message(%CallResult{} = call_result) do
      %ToolCall{} = tool_call = call_result.tool_call

      %AnyTalker.AI.Message{
        role: "tool",
        tool_call_id: tool_call.tool_call_id,
        content: CallResult.to_content(call_result)
      }
    end
  end
end
