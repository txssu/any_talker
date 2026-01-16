defmodule AnyTalkerBot.AskCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.Subscription
  alias AnyTalker.Accounts.User
  alias AnyTalker.AI.Generation
  alias AnyTalker.AI.Response
  alias AnyTalker.RateLimit.Context
  alias AnyTalker.RateLimit.TokenBucket
  alias AnyTalker.Settings
  alias AnyTalker.Settings.ChatConfig
  alias AnyTalker.TypedStructAccess
  alias AnyTalkerBot.AskCommand.ResponseBlock
  alias AnyTalkerBot.HtmlUtils
  alias AnyTalkerBot.Reply
  alias ExGram.Model.Message

  require Logger
  require TypedStructAccess

  @time_buffer_ms to_timeout(minute: 5)

  defguard not_empty_string(s) when is_binary(s) and s != ""

  @impl AnyTalkerBot.Command
  def call(%Reply{message: {:command, command, message}} = reply) when command in [:ask, :ask_detailed] do
    bot_id = reply.context.bot_info.id
    is_group = reply.context.extra.is_group
    response_mode = if command == :ask_detailed, do: :detailed, else: :short

    user_with_sub = Accounts.preload_current_subscription(reply.context.extra.user)
    config = Settings.get_full_chat_config(message.chat.id)

    with :ok <- validate_chat_type(user_with_sub, is_group),
         :ok <- validate_config(user_with_sub, config),
         :ok <- validate_not_empty(message, bot_id),
         :ok <- validate_rate_limit(user_with_sub, config) do
      envelope_context = %AnyTalker.AI.Envelope.Context{
        chat: config,
        author: user_with_sub,
        bot_id: bot_id,
        response_mode: response_mode
      }

      reply(reply, message, envelope_context)
    else
      error -> error_reply(error, reply, user_with_sub, config)
    end
  end

  defp error_reply({:error, :not_group}, %Reply{} = reply, %User{} = user_with_sub, %ChatConfig{} = config) do
    text =
      if is_nil(user_with_sub.current_subscription) and config.promote_pro do
        """
        Эта команда работает только в группах.
        Без PRO ты здесь никто.

        Хочешь использовать её где угодно, даже наедине с ботом?
        Бери PRO-подписку. Без неё сюда дороги нет.

        /que_pro — решай сам.
        """
      else
        """
        Эта команда работает только в группах.
        """
      end

    Reply.send_message(reply, text, as_reply?: true)
  end

  defp error_reply({:error, :not_enabled}, %Reply{} = reply, %User{} = user_with_sub, %ChatConfig{} = config) do
    text =
      if is_nil(user_with_sub.current_subscription) and config.promote_pro do
        """
        Здесь бот для тебя мёртв.
        У тебя нет доступа к его командам.

        Два пути:
        — добейся, чтобы админ добавил доступ,
        — или возьми PRO-подписку и открой всё сам.

        /que_pro — твой выбор.
        """
      else
        """
        Здесь бот для тебя мёртв.
        У тебя нет доступа к его командам.
        """
      end

    Reply.send_message(reply, text, as_reply?: true)
  end

  defp error_reply({:error, :empty_text}, %Reply{} = reply, _user_with_sub, _config) do
    Reply.send_message(reply, "Не вижу вопроса!", as_reply?: true)
  end

  defp error_reply({:error, :rate_limit, time_left_ms}, %Reply{} = reply, _user_with_sub, _config) do
    text =
      """
      Ты выжал лимит.
      Следующая попытка будет доступна через #{format_time(time_left_ms)}.
      """

    Reply.send_message(reply, text, as_reply?: true)
  end

  defp format_time(time_left_ms) do
    time_with_buffer_ms = time_left_ms + @time_buffer_ms

    hours = div(time_with_buffer_ms, 3_600_000)
    minutes = div(rem(time_with_buffer_ms, 3_600_000), 60_000)

    [format_unit(hours, "час", "часа", "часов"), format_unit(minutes, "минуту", "минуты", "минут")]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp format_unit(0, _singular, _few, _many), do: nil
  defp format_unit(n, singular, few, many), do: "#{n} #{pluralize(n, singular, few, many)}"

  defp reply(%Reply{} = reply, message, envelope_context) do
    result =
      message
      |> AnyTalker.AI.Envelope.Source.to_envelope(envelope_context)
      |> AnyTalker.AI.request()

    case result do
      {:ok, %Generation{} = gen} ->
        user = envelope_context.author
        config = envelope_context.chat

        consume_tokens(user, config, gen.response)

        text =
          gen.response.data.content
          |> HtmlUtils.escape_html_preserving_tags()
          |> replace_keywords()
          |> ResponseBlock.prepend_all(gen, user)
          |> format_response_with_bot_name(config)

        Reply.send_message(reply, text,
          mode: :html,
          as_reply?: true,
          on_sent: fn %Message{} = msg ->
            AnyTalker.AI.save_request_history(gen, msg)
          end
        )

      {:error, reason} ->
        Logger.error("AI request failed", details: %{reason: reason})
        Reply.send_message(reply, "Да не", as_reply?: true)
    end
  end

  defp consume_tokens(%User{} = user, %ChatConfig{} = config, %Response{} = response) do
    tokens_used = Response.total_tokens(response)

    if tokens_used > 0 do
      key = "ask:#{user.id}"

      context = %Context{
        max_tokens: config.ask_max_tokens,
        refill_interval_ms: config.ask_refill_interval_ms,
        refill_amount: config.ask_refill_amount
      }

      TokenBucket.increase(key, tokens_used, context)
    end
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
       when not_empty_string(t) or not_empty_string(c) or is_list(p), do: :ok

  defp validate_not_empty(_otherwise, _bot_id), do: {:error, :empty_text}

  def validate_rate_limit(%User{} = user, %ChatConfig{} = config) do
    key = "ask:#{user.id}"

    context = %Context{
      max_tokens: config.ask_max_tokens,
      refill_interval_ms: config.ask_refill_interval_ms,
      refill_amount: config.ask_refill_amount
    }

    if TokenBucket.allowed?(key, context) do
      :ok
    else
      time_left_ms = TokenBucket.time_until_allowed(key, context) || context.refill_interval_ms
      {:error, :rate_limit, time_left_ms}
    end
  end

  defp replace_keywords(text) do
    text
    |> String.replace(~r/достаточно/iu, "#достаточно")
    |> String.replace(~r/не\s+нужно/iu, "#ненужно")
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
