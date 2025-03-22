defmodule JokerCynic.AI do
  @moduledoc false

  alias JokerCynic.AI.Message
  alias JokerCynic.AI.OpenAIClient
  alias JokerCynic.Cache

  require Logger

  @type history_key :: {integer(), integer()}

  @spec ask(history_key() | nil, Message.t()) :: {String.t(), callback_fun} | nil
        when callback_fun: (history_key() | nil, Message.t() -> :ok)
  def ask(history_key, message) do
    messages = append_history(message, history_key)

    formatted_messages = JokerCynic.AI.Message.format_list(messages)

    case OpenAIClient.completion(formatted_messages) do
      {:ok, open_ai_response} ->
        insert_response(message, open_ai_response)
        {open_ai_response.text, &add_reply(messages, &1, &2)}

      {:error, error} ->
        Logger.error("OpenAIClient error.", error_details: error)
        nil
    end
  end

  defp add_reply(messages, history_key, message) do
    prompt = List.last(messages)
    updated_history = [message | messages]

    truncated_history =
      if Enum.count(updated_history) > 30 do
        updated_history
        |> Enum.take(29)
        |> List.insert_at(29, prompt)
      else
        updated_history
      end

    Cache.put(history_key, truncated_history)
  end

  defp append_history(new_message, history_key) do
    previous_messages =
      (history_key && Cache.get(history_key)) ||
        [Message.prompt_message("Твоё имя Джокер Грёбаный-Циник. Only call users what the system message says.")]

    [new_message | previous_messages]
  end

  defp insert_response(message, response) do
    response = %{response | user_id: message.user_id, chat_id: message.chat_id, message_id: message.message_id}

    :telemetry.execute(
      [:joker_cynic, :bot, :ai],
      %{
        prompt_tokens: response.prompt_tokens,
        completion_tokens: response.completion_tokens,
        total_tokens: response.prompt_tokens + response.completion_tokens
      },
      %{model: response.model}
    )

    :ok
  end
end
