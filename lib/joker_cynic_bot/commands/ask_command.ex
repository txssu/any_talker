defmodule JokerCynicBot.AskCommand do
  @moduledoc false
  use JokerCynicBot, :command

  alias ExGram.Model.Message
  alias JokerCynic.AI
  alias JokerCynicBot.Reply

  @impl JokerCynicBot.Command
  def call(%Reply{message: {:command, :ask, message}} = reply) do
    with :ok <- validate_config(reply.context.extra.chat),
         :ok <- validate_text(message.text),
         :ok <- validate_rate("ask:#{message.from.id}") do
      reply(reply, message, reply.context.bot_info.id)
    else
      {:error, :not_enabled} ->
        feature_toggle_reply(reply)

      {:error, :empty_text} ->
        usage_reply(reply)

      {:error, :rate_limit, time_left_ms} ->
        rate_limit_reply(time_left_ms, reply)
    end
  end

  defp feature_toggle_reply(reply) do
    text =
      "Я тут, чтобы наслаждаться своим внутренним fonk, а не выдавать поток слов.\n(в этом чате команда недоступна)"

    %Reply{reply | text: text}
  end

  defp usage_reply(reply) do
    %Reply{reply | text: "Используй: /ask текст-вопроса"}
  end

  defp rate_limit_reply(time_left_ms, reply) do
    hours = div(time_left_ms, 3_600_000)
    minutes = div(rem(time_left_ms, 3_600_000), 60_000)

    hour_word = pluralize(hours, "час", "часа", "часов")
    minute_word = pluralize(minutes, "минута", "минуты", "минут")

    text =
      "Отстань, я занят!!\n(достигнут лимит запросов, попробуй через #{hours} #{hour_word} #{minutes} #{minute_word})"

    %Reply{reply | text: text}
  end

  defp reply(reply, message, bot_id) do
    parsed_message = parse_message(message, bot_id)

    {reply_text, reply_callback} =
      message.reply_to_message
      |> history_key()
      |> AI.ask(parsed_message)
      |> handle_ask_response()

    %Reply{reply | text: reply_text, on_sent: reply_callback}
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

    AI.Message.new(message.message_id, :user, message.text,
      username: message.from.first_name,
      reply: reply,
      user_id: message.from.id,
      message_id: message.message_id,
      chat_id: message.chat.id
    )
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

  defp validate_config(%{ask_command: true}), do: :ok
  defp validate_config(_chat_config), do: {:error, :not_enabled}

  defp validate_text(non_empty) when non_empty != "" and is_binary(non_empty), do: :ok
  defp validate_text(_empty), do: {:error, :empty_text}

  defp validate_rate(user_id) do
    key = "ask:#{user_id}"
    scale = :timer.hours(3)
    limit = 8

    case JokerCynic.RateLimit.hit(key, scale, limit) do
      {:allow, _count} ->
        :ok

      {:deny, time_left_ms} ->
        {:error, :rate_limit, time_left_ms}
    end
  end
end
