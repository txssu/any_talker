defmodule AnyTalker.AI do
  @moduledoc false
  alias AnyTalker.AI.Envelope
  alias AnyTalker.AI.History
  alias AnyTalker.AI.Request
  alias AnyTalker.AI.Response
  alias AnyTalker.AI.ToMessage
  alias AnyTalker.AI.Tool

  def request(%Envelope{} = envelope) do
    history_key = History.Storable.to_key(envelope)
    history = History.get(history_key)

    messages =
      history
      |> History.append(Envelope.messages(envelope))
      |> History.messages()

    req = %Request{
      messages: messages,
      instructions: Envelope.instructions(envelope),
      models: envelope.models,
      tools: Tool.Registry.list(),
      function_context: Envelope.function_context(envelope)
    }

    generate(req)
  end

  def save_request_history(%History{} = history, %ExGram.Model.Message{} = message) do
    history_key = History.Storable.to_key(message)
    updated_history = History.set_last_uniq_key(history, message.message_id)
    History.put(history_key, updated_history)
  end

  def generate(%Request{} = req) do
    do_generate(req, 0)
  end

  def do_generate(%Request{} = req, tool_calls) do
    with {:ok, %Response{} = response} <- AnyTalker.AI.OpenRouterClient.completions(req) do
      case response.data do
        %Response.ToolCall{} ->
          tool_call_msg = ToMessage.to_message(response)
          call_result = Tool.execute(response.data, req.function_context, tool_calls)
          call_result_msg = ToMessage.to_message(call_result)
          do_generate(%{req | messages: req.messages ++ [tool_call_msg, call_result_msg]}, tool_calls + 1)

        _another ->
          history =
            req.messages
            |> History.new()
            |> History.append(ToMessage.to_message(response))

          {:ok, response, history}
      end
    end
  end
end
