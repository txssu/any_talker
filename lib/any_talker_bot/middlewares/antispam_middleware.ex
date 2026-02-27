defmodule AnyTalkerBot.AntispamMiddleware do
  @moduledoc false
  use ExGram.Middleware

  alias AnyTalker.Antispam

  @dickgrower_bot_id 6_465_471_545

  @impl ExGram.Middleware
  def call(context, _options) do
    case context.extra.chat do
      nil -> context
      chat -> do_call(context.update.message, chat, context)
    end
  end

  defp do_call(%{via_bot: %{id: @dickgrower_bot_id}} = message, %{antispam_via: true}, context) do
    ExGram.delete_message(message.chat.id, message.message_id, bot: AnyTalkerBot.bot())
    halt(context)
  end

  defp do_call(%{new_chat_members: new_chat_members} = message, %{antispam_captcha: true}, context)
       when is_list(new_chat_members) do
    bot_id = context.bot_info.id

    new_chat_members
    |> Enum.reject(&(&1.id == bot_id))
    |> Enum.each(&Antispam.create_captcha(&1.id, &1.first_name, message.chat.id, message.message_id))

    halt(context)
  end

  defp do_call(%{left_chat_member: left_chat_member} = message, %{antispam_captcha: true}, context)
       when is_map(left_chat_member) do
    case Antispam.get_captcha(left_chat_member.id, message.chat.id) do
      %{status: status} when status in ~w[failed timed_out]a ->
        ExGram.delete_message(message.chat.id, message.message_id, bot: AnyTalkerBot.bot())

      _captcha ->
        :ok
    end

    halt(context)
  end

  defp do_call(message, chat, context) do
    if chat.antispam_keywords_enabled && contains_forbidden_keyword?(message.text, chat.antispam_keywords) do
      ExGram.delete_message(message.chat.id, message.message_id, bot: AnyTalkerBot.bot())
      halt(context)
    else
      maybe_resolve_captcha(message, chat, context)
    end
  end

  defp maybe_resolve_captcha(%{text: nil}, _chat, context), do: context

  defp maybe_resolve_captcha(message, %{antispam_captcha: true} = _chat, context) do
    case Antispam.get_captcha(message.from.id, message.chat.id) do
      nil ->
        context

      captcha ->
        Antispam.try_resolve_captcha(captcha, message.text, message.message_id)
        halt(context)
    end
  end

  defp maybe_resolve_captcha(_message, _chat, context), do: context

  defp contains_forbidden_keyword?(nil, _keywords), do: false
  defp contains_forbidden_keyword?(_text, nil), do: false
  defp contains_forbidden_keyword?(_text, ""), do: false

  defp contains_forbidden_keyword?(text, keywords) do
    text_downcase = String.downcase(text)

    keywords
    |> String.split()
    |> Enum.any?(&String.contains?(text_downcase, String.downcase(&1)))
  end
end
