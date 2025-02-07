defmodule JokerCynicBot.AskCommand do
  @moduledoc false
  use JokerCynicBot, :command

  alias ExGram.Model.Message
  alias JokerCynic.AI
  alias JokerCynicBot.Reply

  @impl JokerCynicBot.Command
  def call(%Reply{message: {:command, :ask, message}, context: %{bot_info: %{id: bot_id}}} = reply) do
    case message.text do
      "" ->
        %Reply{reply | text: "Используй: /ask текст-вопроса"}

      _non_empty ->
        parsed_message = parse_message(message, bot_id)

        {reply_text, reply_callback} =
          message.reply_to_message
          |> history_key()
          |> AI.ask(parsed_message)
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

  defp parse_message(message, bot_id) do
    reply =
      if reply = message.reply_to_message do
        role = if reply.from.id == bot_id, do: :assistant, else: :user
        quote_text = message.quote && message.quote.text
        AI.Message.new(reply.message_id, role, reply.text, username: reply.from.first_name, quote: quote_text)
      end

    AI.Message.new(message.message_id, :user, message.text, username: message.from.first_name, reply: reply)
  end

  defp format_callback(reply_callback) do
    fn message ->
      key = history_key(message)
      message = AI.Message.new(message.message_id, :assistant, message.text)
      reply_callback.(key, message)
    end
  end

  defp history_key(nil) do
    nil
  end

  defp history_key(%Message{chat: chat, message_id: message_id}) do
    {chat.id, message_id}
  end
end
