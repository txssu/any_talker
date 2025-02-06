defmodule JokerCynicBot.AskCommand do
  @moduledoc false
  use JokerCynicBot, :command

  alias JokerCynic.AI
  alias JokerCynicBot.Reply

  @impl JokerCynicBot.Command
  def call(%Reply{message: {:command, :ask, message}} = reply) do
    case message.text do
      "" ->
        %Reply{reply | text: "Используй: /ask текст-вопроса"}

      _non_empty ->
        {reply_text, reply_callback} =
          message.from.first_name
          |> AI.ask(message.text, history_key(message.reply_to_message))
          |> handle_ask_response()

        %Reply{reply | text: reply_text, on_sent: reply_callback}
    end
  end

  defp handle_ask_response(nil) do
    {"Да не", nil}
  end

  defp handle_ask_response({reply_text, reply_callback}) do
    {reply_text, format_callback(reply_callback)}
  end

  defp format_callback(reply_callback) do
    fn message ->
      message
      |> history_key()
      |> reply_callback.()
    end
  end

  defp history_key(nil) do
    nil
  end

  defp history_key(%ExGram.Model.Message{chat: chat, message_id: message_id}) do
    {chat.id, message_id}
  end
end
