defmodule AnyTalker.AI do
  @moduledoc false

  alias AnyTalker.AI.Attachments
  alias AnyTalker.AI.Context
  alias AnyTalker.AI.FunctionCall
  alias AnyTalker.AI.History
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
         common = [
           model: config.ask_model,
           instructions: instructions(config.ask_prompt),
           tools: ToolsRegistry.list_specs()
         ],
         {:ok, response, result_history} <- request_response(request_history, common, context) do
      {response.output_text, make_callback(result_history, response)}
    else
      {:error, error} ->
        Logger.error("OpenAiClientError", error_details: error)
        nil
    end
  end

  defp make_callback(%History{} = history, %Response{} = response) do
    fn %History.Key{} = key, message_id ->
      message = Message.new(message_id, :assistant, response.output_text, DateTime.utc_now())

      History.put(key, History.append(history, message))
    end
  end

  defp request_response(%History{} = history, common, %Context{} = context) do
    body = Keyword.put(common, :input, Message.format_list(history.messages))

    with {:ok, response} <- OpenAIClient.response(body) do
      hit_metrics(response)

      case response do
        %Response{function_call: %FunctionCall{} = function_call} ->
          tool_call_message =
            FunctionToolCall.new(
              function_call.call_id,
              function_call.name,
              function_call.arguments_json
            )

          history_with_call = History.append(history, tool_call_message)
          call_result = FunctionCall.exec(function_call, context)
          history_with_result = History.append(history_with_call, call_result)

          request_response(history_with_result, common, context)

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

  defp instructions(prompt) do
    base_prompt = prompt || AnyTalker.GlobalConfig.get(:ask_prompt)

    json_instructions = """

    # Формат сообщений

    Сообщения пользователей приходят в JSON формате со следующими полями:
    - `text`: основной текст сообщения
    - `username`: имя отправителя (только для пользователей)
    - `sent_at`: точное время отправки сообщения
    - `quote`: цитируемый текст из сообщения, на которое отвечает пользователь (если есть)

    ВАЖНО: Поле `sent_at` показывает реальное время отправки каждого сообщения. Время последнего сообщения в диалоге - это ТЕКУЩЕЕ ВРЕМЯ СЕЙЧАС.

    # Формат ответа

    Не используй markdown в ответе. Не используй JSON в ответе. Только обычный текст.
    Доступное форматироване:
    - <b>bold</b>
    - <i>italic</i>
    - <u>underline</u>
    - <a href="http://www.example.com/">inline URL</a>
    - <code>inline fixed-width code</code>
    - <pre>pre-formatted fixed-width code block</pre>
    - <pre><code class="language-python">pre-formatted fixed-width code block written in the Python programming language</code></pre>
    """

    base_prompt <> json_instructions
  end
end
