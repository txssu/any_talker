defmodule JokerCynic.AI do
  @moduledoc false

  alias JokerCynic.AI.ContextStorage
  alias JokerCynic.AI.Message
  alias JokerCynic.AI.OpenAICLient

  require Logger

  @type history_key :: {integer(), integer()}

  @spec ask(String.t(), String.t(), history_key() | nil) :: {String.t(), (history_key() -> :ok)} | nil
  def ask(username, text, history_key) do
    messages =
      username
      |> Message.new_from_user(text)
      |> append_history(history_key)

    fromatted_messages = JokerCynic.AI.Message.format_list(messages)

    case OpenAICLient.completion(fromatted_messages) do
      {:ok, reply_text} ->
        {reply_text, add_reply_callback(reply_text, messages)}

      {:error, error} ->
        Logger.error("OpenAICLient error.", error_details: error)
        nil
    end
  end

  defp add_reply_callback(reply_text, messages) do
    fn history_key ->
      prompt = List.last(messages)
      updated_history = [Message.new_from_assistant(reply_text) | messages]

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
        [Message.new_from_system("Твоё имя Джокер Грёбанный-Циник. Only call users what the system message says.")]

    [new_message | previous_messages]
  end
end
