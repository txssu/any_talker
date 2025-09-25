defmodule AnyTalker.AI do
  @moduledoc false

  alias AnyTalker.AI.Attachments
  alias AnyTalker.AI.Context
  alias AnyTalker.AI.FunctionCall
  alias AnyTalker.AI.History
  alias AnyTalker.AI.Message
  alias AnyTalker.AI.OpenAIClient
  alias AnyTalker.AI.Response
  alias AnyTalker.AI.ToolsRegistry
  alias AnyTalker.Settings

  require Logger

  def ask(%Message{} = message, %Context{} = context, options) do
    %History{} =
      history =
      case Keyword.get(options, :history_key) do
        nil -> History.new()
        key -> History.get(key)
      end

    with {:ok, final_message} <- Attachments.download_message_image(message),
         input = Message.format_message(final_message, history.added_messages_ids),
         config = Settings.get_full_chat_config(message.chat_id),
         common = [
           model: config.ask_model,
           instructions: instructions(config.ask_prompt),
           tools: ToolsRegistry.list_specs()
         ],
         {:ok, response} <-
           request_response(history.response_id, input, common, context) do
      hit_metrics(response)
      {response.output_text, make_callback(response, history)}
    else
      {:error, error} ->
        Logger.error("OpenAiClientError", error_details: error)
        nil
    end
  end

  def make_callback(%Response{} = response, %History{} = old_history) do
    fn %History.Key{} = key, message_id ->
      new_history = History.new(response.id, [message_id | old_history.added_messages_ids])
      History.put(key, new_history)
    end
  end

  # TODO: MOVE
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

  def request_response(response_id, input, common, %Context{} = context) do
    body =
      Keyword.merge(common,
        input: input,
        previous_response_id: response_id
      )

    with {:ok, response} <- OpenAIClient.response(body) do
      case response do
        %Response{function_call: %FunctionCall{} = function_call, id: new_response_id} ->
          call_result = FunctionCall.exec(function_call, context)
          request_response(new_response_id, [call_result], common, context)

        %Response{} = resp ->
          {:ok, resp}
      end
    end
  end

  # TODO: DELETE
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
