defmodule AnyTalker.AI.Generation do
  @moduledoc false
  alias AnyTalker.AI.History
  alias AnyTalker.AI.Request
  alias AnyTalker.AI.Response
  alias AnyTalker.AI.Tool.CallResult

  defstruct [:request, :response, :history, tool_calls_count: 0, call_results: []]

  def new(%Request{} = request) do
    %__MODULE__{request: request}
  end

  def add_call_result(%__MODULE__{} = gen, %CallResult{} = call_result) do
    %{gen | call_results: [call_result | gen.call_results], tool_calls_count: gen.tool_calls_count + 1}
  end

  def update_messages(%__MODULE__{} = gen, messages) do
    %{gen | request: %{gen.request | messages: messages}}
  end

  def set_response(%__MODULE__{} = gen, %Response{} = response) do
    %{gen | response: response}
  end

  def set_history(%__MODULE__{} = gen, %History{} = history) do
    %{gen | history: history}
  end

  def call_results(%__MODULE__{call_results: call_results}) do
    Enum.reverse(call_results)
  end
end
