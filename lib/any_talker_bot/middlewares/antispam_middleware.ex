defmodule AnyTalkerBot.AntispamMiddleware do
  @moduledoc false
  use ExGram.Middleware

  alias AnyTalker.Antispam

  @dickgrower_bot_id 6_465_471_545

  def call(context, _options) do
    case context.extra.chat do
      %{antispam: true} = chat -> do_call(context.update.message, chat, context)
      _other -> context
    end
  end

  defp do_call(%{via_bot: %{id: @dickgrower_bot_id}} = message, _chat, context) do
    ExGram.delete_message(message.chat.id, message.message_id, bot: AnyTalkerBot.bot())
    halt(context)
  end

  defp do_call(%{new_chat_members: new_chat_members} = message, _chat, context) when is_list(new_chat_members) do
    bot_id = context.bot_info.id

    new_chat_members
    |> Enum.reject(&(&1.id == bot_id))
    |> Enum.each(&Antispam.create_captcha(&1.id, &1.first_name, message.chat.id, message.message_id))

    halt(context)
  end

  defp do_call(%{left_chat_member: left_chat_member} = message, _chat, context) when is_map(left_chat_member) do
    captcha = Antispam.get_captcha(left_chat_member.id, message.chat.id)

    if captcha.status in ~w[failed timed_out]a do
      ExGram.delete_message(message.chat.id, message.message_id, bot: AnyTalkerBot.bot())
    end

    halt(context)
  end

  defp do_call(message, chat, context) do
    cond do
      contains_forbidden_keyword?(message.text, chat.antispam_keywords) ->
        ExGram.delete_message(message.chat.id, message.message_id, bot: AnyTalkerBot.bot())
        halt(context)

      captcha = Antispam.get_captcha(message.from.id, message.chat.id) ->
        Antispam.try_resolve_captcha(captcha, message.text, message.message_id)
        halt(context)

      true ->
        context
    end
  end

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
