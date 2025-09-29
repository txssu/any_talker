defmodule AnyTalkerBot.AskCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.Subscription
  alias AnyTalker.Accounts.User
  alias AnyTalker.AI
  alias AnyTalker.AI.History
  alias AnyTalker.Settings
  alias AnyTalker.Settings.ChatConfig
  alias AnyTalkerBot.Attachments
  alias AnyTalkerBot.Reply2
  alias ExGram.Model.Chat
  alias ExGram.Model.Message
  alias ExGram.Model.PhotoSize

  defguard not_empty_string(s) when is_binary(s) and s != ""

  @impl AnyTalkerBot.Command
  def call(%Reply2{message: {:command, :ask, message}} = reply) do
    bot_id = reply.context.bot_info.id
    is_group = reply.context.extra.is_group

    user_with_sub = Accounts.preload_current_subscription(reply.context.extra.user)
    config = Settings.get_full_chat_config(message.chat.id)

    maybe_wait(user_with_sub)

    with :ok <- validate_chat_type(user_with_sub, is_group),
         :ok <- validate_config(user_with_sub, config),
         :ok <- validate_not_empty(message, bot_id),
         :ok <- validate_rate_limit(user_with_sub, config) do
      reply(reply, message, reply.context.bot_info.id)
    else
      error -> error_reply(error, reply)
    end
  end

  defp error_reply({:error, :not_group}, %Reply2{} = reply) do
    text = """
    Эта команда работает только в группах.
    Без PRO ты здесь никто.

    Хочешь использовать её где угодно, даже наедине с ботом?
    Бери PRO-подписку. Без неё сюда дороги нет.

    /que_pro — решай сам.
    """

    Reply2.send_message(reply, text, as_reply?: true)
  end

  defp error_reply({:error, :not_enabled}, %Reply2{} = reply) do
    text = """
    Здесь бот для тебя мёртв.
    У тебя нет доступа к его командам.

    Два пути:
    — добейся, чтобы админ добавил доступ,
    — или возьми PRO-подписку и открой всё сам.

    /que_pro — твой выбор.
    """

    Reply2.send_message(reply, text, as_reply?: true)
  end

  defp error_reply({:error, :empty_text}, %Reply2{} = reply) do
    Reply2.send_message(reply, "Не вижу вопроса!", as_reply?: true)
  end

  defp error_reply({:error, :rate_limit, time_left_ms}, %Reply2{} = reply) do
    text =
      """
      Ты выжал лимит.
      Следующая попытка будет доступна через #{format_time(time_left_ms)}.

      Не хочешь ждать?
      Бери PRO-подписку и используй команды без ограничений.

      👉 /que_pro — решай быстро.
      """

    Reply2.send_message(reply, text, as_reply?: true)
  end

  defp format_time(time_left_ms) do
    hours = div(time_left_ms, 3_600_000)
    minutes = div(rem(time_left_ms, 3_600_000), 60_000)

    [format_unit(hours, "час", "часа", "часов"), format_unit(minutes, "минуту", "минуты", "минут")]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp format_unit(0, _singular, _few, _many), do: nil
  defp format_unit(n, singular, few, many), do: "#{n} #{pluralize(n, singular, few, many)}"

  defp reply(%Reply2{} = reply, message, bot_id) do
    parsed_message = parse_message(message, bot_id)
    config = Settings.get_full_chat_config(message.chat.id)

    {reply_text, reply_callback} =
      parsed_message
      |> AI.ask(build_context(reply), history_key: history_key(message.reply_to_message))
      |> handle_ask_response(config)

    Reply2.send_message(reply, reply_text, on_sent: reply_callback, mode: :html, as_reply?: true)
  end

  defp history_key(nil) do
    nil
  end

  defp history_key(%Message{chat: %Chat{id: chat_id}, message_id: message_id}) do
    History.Key.new(chat_id, message_id)
  end

  defp handle_ask_response(nil, _config) do
    {"Да не", nil}
  end

  defp handle_ask_response({reply_text, reply_callback}, config) do
    formatted_text = format_response_with_bot_name(reply_text, config)
    {formatted_text, &adjust_params(reply_callback, &1)}
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

  defp display_name(%Message{from: from}) do
    from.id
    |> Accounts.get_user()
    |> Accounts.display_name()
    |> Kernel.||(from.first_name)
  end

  defp build_message(message, bot_id) do
    role = if message.from.id == bot_id, do: :assistant, else: :user

    AI.Message.new(message.message_id, role, message.text || message.caption, DateTime.from_unix!(message.date),
      username: display_name(message),
      user_id: message.from.id,
      message_id: message.message_id,
      chat_id: message.chat.id,
      image_url: get_image_url(message)
    )
  end

  defp add_reply(result, %Message{reply_to_message: nil}, _bot_id) do
    result
  end

  defp add_reply(%AnyTalker.AI.Message{} = result, %Message{} = message, bot_id) do
    original_reply = message.reply_to_message
    role = if original_reply.from.id == bot_id, do: :assistant, else: :user
    quote_text = message.quote && message.quote.text

    message_text = original_reply.text || original_reply.caption

    reply =
      AI.Message.new(original_reply.message_id, role, message_text, DateTime.from_unix!(original_reply.date),
        username: display_name(original_reply),
        quote: quote_text,
        image_url: get_image_url(original_reply)
      )

    %{result | reply: reply}
  end

  defp get_image_url(%Message{photo: nil}), do: nil

  defp get_image_url(%Message{photo: photos}) do
    %PhotoSize{file_id: photo_id} = Attachments.best_fit_photo(photos, 1536 * 1024)

    Attachments.get_file_link(photo_id)
  end

  defp adjust_params(reply_callback, message) do
    message
    |> history_key()
    |> reply_callback.(message.message_id)
  end

  defp build_context(%Reply2{} = reply) do
    message = reply.context.update.message

    %AnyTalker.AI.Context{
      chat_id: message.chat.id,
      user_id: message.from.id,
      message_id: message.message_id
    }
  end

  defp validate_chat_type(user_with_sub, group?)
  defp validate_chat_type(%User{current_subscription: %Subscription{plan: :pro}}, _group?), do: :ok
  defp validate_chat_type(_user, true), do: :ok
  defp validate_chat_type(_user, false), do: {:error, :not_group}

  defp validate_config(user_with_sub, chat_config)
  defp validate_config(%User{current_subscription: %Subscription{plan: :pro}}, _chat_config), do: :ok
  defp validate_config(_user, %ChatConfig{ask_command: true}), do: :ok
  defp validate_config(_user, _chat_config), do: {:error, :not_enabled}

  defp validate_not_empty(%Message{text: t, photo: p}, _bot_id) when not_empty_string(t) or is_list(p), do: :ok

  defp validate_not_empty(%Message{reply_to_message: %Message{from: %{id: bot_id}}}, bot_id), do: {:error, :empty_text}

  defp validate_not_empty(%Message{reply_to_message: %Message{text: t, caption: c, photo: p}}, _bot_id)
       when not_empty_string(t) or not_empty_string(c) or is_list(p),
       do: :ok

  defp validate_not_empty(_otherwise, _bot_id), do: {:error, :empty_text}

  def validate_rate_limit(%User{current_subscription: sub} = user, %ChatConfig{} = config) do
    {scale, limit} =
      case sub do
        nil ->
          {config.ask_rate_limit_scale_ms, config.ask_rate_limit}

        %Subscription{plan: :pro} ->
          {config.ask_pro_rate_limit_scale_ms, config.ask_pro_rate_limit}
      end

    key = "ask:#{user.id}"

    case AnyTalker.RateLimit.hit(key, scale, limit) do
      {:allow, _count} ->
        :ok

      {:deny, time_left_ms} ->
        {:error, :rate_limit, time_left_ms}
    end
  end

  defp maybe_wait(%User{current_subscription: %Subscription{plan: :pro}}), do: nil

  defp maybe_wait(_user) do
    [second: 5]
    |> to_timeout()
    |> Process.sleep()
  end

  defp format_response_with_bot_name(reply_text, config) do
    bot_name = config.bot_name

    if not is_nil(bot_name) and bot_name != "" do
      """
      <b>#{bot_name}</b>:
      #{reply_text}
      """
    else
      reply_text
    end
  end
end
