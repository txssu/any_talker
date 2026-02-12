defmodule AnyTalker.AI.Generation do
  @moduledoc false
  alias AnyTalker.AI.History
  alias AnyTalker.AI.Request
  alias AnyTalker.AI.Response
  alias AnyTalker.AI.Tool.CallResult

  defstruct [
    :request,
    :response,
    :history,
    tool_calls_count: 0,
    call_results: [],
    total_cost: Decimal.new(0),
    total_tokens: 0
  ]

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

  def accumulate_usage(%__MODULE__{} = gen, %Response{} = response) do
    %{
      gen
      | total_cost: Decimal.add(gen.total_cost, Response.cost(response)),
        total_tokens: gen.total_tokens + Response.total_tokens(response)
    }
  end

  def call_results(%__MODULE__{call_results: call_results}) do
    Enum.reverse(call_results)
  end
end
