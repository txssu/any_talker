defmodule AnyTalker.AI do
  @moduledoc false

  alias AnyTalker.AI.Attachments
  alias AnyTalker.AI.Context
  alias AnyTalker.AI.FunctionCall
  alias AnyTalker.AI.History
  alias AnyTalker.AI.Instruction
  alias AnyTalker.AI.Message
  alias AnyTalker.AI.Message.FunctionToolCall
  alias AnyTalker.AI.Message.Input
  alias AnyTalker.AI.OpenAIClient
  alias AnyTalker.AI.Response
  alias AnyTalker.AI.ToolsRegistry
  alias AnyTalker.Settings

  require Logger

  def ask(%Input{} = message, %Context{} = context, options) do
    %History{} =
      history =
      case Keyword.get(options, :history_key) do
        nil -> History.new()
        key -> History.get(key)
      end

    with {:ok, final_message} <- Attachments.download_message_image(message),
         request_history = History.append(history, final_message),
         config = Settings.get_full_chat_config(message.chat_id),
         system_message = create_system_message(config.ask_prompt),
         common = [
           model: config.ask_model,
           tools: ToolsRegistry.list_specs()
         ],
         {:ok, response, result_history} <-
           request_response(request_history, system_message, common, context) do
      {response.output_text, make_callback(result_history, response)}
    else
      {:error, error} ->
        Logger.error("OpenAiClientError", error_details: error)
        nil
    end
  end

  defp create_system_message(prompt) do
    instructions_text = Instruction.build(prompt)
    Message.new("system", :system, instructions_text, DateTime.utc_now())
  end

  defp make_callback(%History{} = history, %Response{} = response) do
    fn %History.Key{} = key, message_id ->
      message = Message.new(message_id, :assistant, response.output_text, DateTime.utc_now())

      History.put(key, History.append(history, message))
    end
  end

  # Prepares messages for API request by formatting history and prepending system message.
  # System message is added only for the request and is not saved in history.
  defp prepare_messages(%History{} = history, system_message) do
    formatted_history = Message.format_list(history.messages)
    formatted_system = Input.format_message(system_message)

    [formatted_system | formatted_history]
  end

  defp request_response(%History{} = history, system_message, common, %Context{} = context) do
    body = Keyword.put(common, :input, prepare_messages(history, system_message))

    with {:ok, response} <- OpenAIClient.response(body) do
      hit_metrics(response)

      case response do
        %Response{function_call: %FunctionCall{} = function_call} ->
          tool_call_message =
            FunctionToolCall.new(
              function_call.call_id,
              function_call.name,
              function_call.arguments_json,
              function_call.id
            )

          history_with_call = History.append(history, tool_call_message)
          call_result = FunctionCall.exec(function_call, context)
          history_with_result = History.append(history_with_call, call_result)

          request_response(history_with_result, system_message, common, context)

        %Response{} = resp ->
          {:ok, resp, history}
      end
    end
  end

  defp hit_metrics(response) do
    :telemetry.execute(
      [:any_talker, :bot, :ai],
      %{
        total_tokens: response.total_tokens
      },
      %{model: response.model}
    )

    :ok
  end
end
