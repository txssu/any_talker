defmodule AnyTalker.AI do
  @moduledoc false

  alias AnyTalker.AI.Message
  alias AnyTalker.AI.OpenAIClient
  alias AnyTalker.Cache
  alias AnyTalker.Settings

  require Logger

  @type history_key :: {integer(), integer()}

  @spec ask(history_key() | nil, Message.t()) :: {String.t(), callback_fun} | nil
        when callback_fun: (history_key(), message_id :: integer() -> :ok)
  def ask(history_key, message) do
    {response_id, added_messages_ids} = get_history_data(history_key)

    with {:ok, final_message} <- AnyTalker.AI.Attachments.download_message_image(message),
         input = Message.format_message(final_message, added_messages_ids),
         config = Settings.get_full_chat_config(message.chat_id),
         model = config.ask_model,
         prompt = config.ask_prompt,
         {:ok, response} <-
           OpenAIClient.response(
             input: input,
             previous_response_id: response_id,
             model: model,
             instructions: instructions(prompt)
           ) do
      hit_metrics(response)
      {response.output_text, &Cache.put(&1, {response.id, [&2 | added_messages_ids]})}
    else
      {:error, error} ->
        Logger.error("OpenAiClientError", error_details: error)
        nil
    end
  end

  defp get_history_data(history_key) do
    case Cache.get(history_key) do
      nil -> {nil, []}
      value -> value
    end
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
    """

    base_prompt <> json_instructions
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
