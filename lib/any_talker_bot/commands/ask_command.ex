defmodule AnyTalkerBot.AskCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.User
  alias AnyTalker.AI.Generation
  alias AnyTalker.Settings
  alias AnyTalker.Settings.ChatConfig
  alias AnyTalkerBot.HtmlUtils
  alias AnyTalkerBot.Reply
  alias AnyTalkerBot.Shared.Ask
  alias AnyTalkerBot.Shared.ResponseBlock
  alias ExGram.Model.Message

  require Logger

  defguard not_empty_string(s) when is_binary(s) and s != ""

  @impl AnyTalkerBot.Command
  def call(%Reply{} = reply, command) when command in [:ask, :ask_detailed] do
    %Message{} = message = Reply.message(reply)
    bot_id = reply.context.bot_info.id
    is_group = reply.context.extra.is_group
    response_mode = if command == :ask_detailed, do: :detailed, else: :short

    user_with_sub = Accounts.preload_current_subscription(reply.context.extra.user)
    config = Settings.get_full_chat_config(message.chat.id)

    with :ok <- validate_access(user_with_sub, is_group, config),
         :ok <- validate_not_empty(message, bot_id) do
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

  defp error_reply({:error, :banned}, %Reply{} = reply, _user_with_sub, _config) do
    Reply.halt(reply)
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
    text = """
    Ты выжал лимит.
    Следующая попытка будет доступна через #{Ask.format_time(time_left_ms)}.
    """

    Reply.send_message(reply, text, as_reply?: true)
  end

  defp reply(%Reply{} = reply, message, envelope_context) do
    result =
      message
      |> AnyTalker.AI.Envelope.Source.to_envelope(envelope_context)
      |> AnyTalker.AI.request()

    case result do
      {:ok, %Generation{} = gen} ->
        user = envelope_context.author
        config = envelope_context.chat

        Ask.consume_tokens(user, config, gen.response)

        text =
          gen.response.data.content
          |> HtmlUtils.escape_html_preserving_tags()
          |> Ask.replace_keywords()
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

  defp validate_access(%User{} = user, group?, %ChatConfig{} = config) do
    if user.admin do
      :ok
    else
      with :ok <- Ask.validate_not_banned(user),
           :ok <- validate_group_and_config(user, group?, config) do
        Ask.validate_rate_limit(user, config)
      end
    end
  end

  defp validate_group_and_config(user, group?, config) do
    with {:error, :not_pro} <- Ask.validate_pro(user),
         :ok <- validate_chat_type(group?) do
      validate_config(config)
    end
  end

  defp validate_chat_type(true), do: :ok
  defp validate_chat_type(false), do: {:error, :not_group}

  defp validate_config(%ChatConfig{ask_command: true}), do: :ok
  defp validate_config(_chat_config), do: {:error, :not_enabled}

  defp validate_not_empty(%Message{text: t, photo: p}, _bot_id) when not_empty_string(t) or is_list(p), do: :ok

  defp validate_not_empty(%Message{reply_to_message: %Message{from: %{id: bot_id}}}, bot_id), do: {:error, :empty_text}

  defp validate_not_empty(%Message{reply_to_message: %Message{text: t, caption: c, photo: p}}, _bot_id)
       when not_empty_string(t) or not_empty_string(c) or is_list(p), do: :ok

  defp validate_not_empty(_otherwise, _bot_id), do: {:error, :empty_text}

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
