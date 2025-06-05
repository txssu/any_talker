defmodule AnyTalkerBot.AskCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.AI
  alias AnyTalker.GlobalConfig
  alias AnyTalkerBot.Attachments
  alias AnyTalkerBot.Reply
  alias ExGram.Model.Message
  alias ExGram.Model.PhotoSize

  defguard not_empty_string(s) when is_binary(s) and s != ""

  @impl AnyTalkerBot.Command
  def call(%Reply{message: {:command, :ask, message}} = reply) do
    bot_id = reply.context.bot_info.id

    with :ok <- validate_is_group(reply.context.extra.is_group),
         :ok <- validate_config(reply.context.extra.chat),
         :ok <- validate_not_empty(message, bot_id),
         :ok <- validate_rate("ask:#{message.from.id}") do
      reply(reply, message, reply.context.bot_info.id)
    else
      error -> error_reply(error, reply)
    end
  end

  defp error_reply({:error, :not_group}, reply) do
    text = """
    разговаривать приватно с серой массой — всё равно что обсуждать "Войну и мир" с шулерами, господин, я предпочитаю лишь публичные трибуны для демонстрации своего величия.
    (команда доступна только в чатах)
    """

    %{reply | text: text}
  end

  defp error_reply({:error, :not_enabled}, reply) do
    text =
      "Я тут, чтобы наслаждаться своим внутренним fonk, а не выдавать поток слов.\n(в этом чате команда недоступна)"

    %{reply | text: text}
  end

  defp error_reply({:error, :empty_text}, reply) do
    %{reply | text: "Не вижу вопроса!"}
  end

  defp error_reply({:error, :rate_limit, time_left_ms}, reply) do
    %{
      reply
      | text: "Отстань, я занят!!\n(достигнут лимит запросов, попробуй через #{format_time(time_left_ms)})"
    }
  end

  defp format_time(time_left_ms) do
    hours = div(time_left_ms, 3_600_000)
    minutes = div(rem(time_left_ms, 3_600_000), 60_000)

    [format_unit(hours, "час", "часа", "часов"), format_unit(minutes, "минута", "минуты", "минут")]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp format_unit(0, _singular, _few, _many), do: nil
  defp format_unit(n, singular, few, many), do: "#{n} #{pluralize(n, singular, few, many)}"

  defp reply(reply, message, bot_id) do
    parsed_message = parse_message(message, bot_id)
    prompt = AI.prompt(reply.context.extra.chat)

    {reply_text, reply_callback} =
      message.reply_to_message
      |> history_key()
      |> AI.ask(parsed_message, prompt)
      |> handle_ask_response()

    %{reply | text: reply_text, on_sent: reply_callback}
  end

  defp handle_ask_response(nil) do
    {"Да не", nil}
  end

  defp handle_ask_response({reply_text, reply_callback}) do
    {reply_text, &adjust_params(reply_callback, &1)}
  end

  defp parse_message(%Message{text: t, caption: c, photo: p} = message, bot_id)
       when not_empty_string(t) or not_empty_string(c) or not is_nil(p) do
    message
    |> build_message(bot_id)
    |> add_reply(message, bot_id)
  end

  defp parse_message(%Message{reply_to_message: %Message{} = message}, bot_id) do
    parse_message(message, bot_id)
  end

  defp build_message(message, bot_id) do
    role = if message.from.id == bot_id, do: :assistant, else: :user

    AI.Message.new(message.message_id, role, message.text || message.caption,
      username: message.from.first_name,
      user_id: message.from.id,
      message_id: message.message_id,
      chat_id: message.chat.id,
      image_url: get_image_url(message)
    )
  end

  defp add_reply(result, %Message{reply_to_message: nil}, _bot_id) do
    result
  end

  defp add_reply(result, message, bot_id) do
    original_reply = message.reply_to_message
    role = if original_reply.from.id == bot_id, do: :assistant, else: :user
    quote_text = message.quote && message.quote.text

    message_text = original_reply.text || original_reply.caption

    reply =
      AI.Message.new(original_reply.message_id, role, message_text,
        username: original_reply.from.first_name,
        quote: quote_text,
        image_url: get_image_url(original_reply)
      )

    %{result | reply: reply}
  end

  defp get_image_url(%Message{photo: nil}), do: nil

  defp get_image_url(%Message{photo: photos}) do
    %PhotoSize{file_id: photo_id} = Attachments.best_fit_photo(photos)

    Attachments.get_file_link(photo_id)
  end

  defp adjust_params(reply_callback, message) do
    message
    |> history_key()
    |> reply_callback.(message.message_id)
  end

  defp history_key(nil) do
    nil
  end

  defp history_key(%Message{chat: chat, message_id: message_id}) do
    {chat.id, message_id}
  end

  defp validate_is_group(true), do: :ok
  defp validate_is_group(_otherwise), do: {:error, :not_group}

  defp validate_config(%{ask_command: true}), do: :ok
  defp validate_config(_chat_config), do: {:error, :not_enabled}

  defp validate_not_empty(%Message{text: t, photo: p}, _bot_id) when not_empty_string(t) or is_list(p), do: :ok

  defp validate_not_empty(%Message{reply_to_message: %Message{from: %{id: bot_id}}}, bot_id), do: {:error, :empty_text}

  defp validate_not_empty(%Message{reply_to_message: %Message{text: t, caption: c, photo: p}}, _bot_id)
       when not_empty_string(t) or not_empty_string(c) or is_list(p),
       do: :ok

  defp validate_not_empty(_otherwise, _bot_id), do: {:error, :empty_text}

  defp validate_rate(user_id) do
    key = "ask:#{user_id}"
    scale = GlobalConfig.get(:ask_rate_limit_scale_ms)
    limit = GlobalConfig.get(:ask_rate_limit)

    case AnyTalker.RateLimit.hit(key, scale, limit) do
      {:allow, _count} ->
        :ok

      {:deny, time_left_ms} ->
        {:error, :rate_limit, time_left_ms}
    end
  end
end
