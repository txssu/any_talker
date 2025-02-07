defmodule JokerCynic.AI do
  @moduledoc false

  alias JokerCynic.AI.ContextStorage
  alias JokerCynic.AI.Message
  alias JokerCynic.AI.OpenAIClient

  require Logger

  @type history_key :: {integer(), integer()}

  @spec ask(history_key() | nil, Message.t()) :: {String.t(), callback_fun} | nil
        when callback_fun: (history_key() | nil, Message.t() -> :ok)
  def ask(history_key, message) do
    messages = append_history(message, history_key)

    formatted_messages = JokerCynic.AI.Message.format_list(messages)

    case OpenAIClient.completion(formatted_messages) do
      {:ok, reply_text} ->
        {reply_text, add_reply_callback(messages)}

      {:error, error} ->
        Logger.error("OpenAIClient error.", error_details: error)
        nil
    end
  end

  defp add_reply_callback(messages) do
    fn history_key, message ->
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

      ContextStorage.put(history_key, truncated_history)
    end
  end

  defp append_history(new_message, history_key) do
    previous_messages =
      (history_key && ContextStorage.get(history_key)) ||
        [Message.prompt_message("Твоё имя Джокер Грёбаный-Циник. Only call users what the system message says.")]

    [new_message | previous_messages]
  end
end
