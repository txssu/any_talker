defmodule AnyTalkerBot.AntispamMiddleware do
  @moduledoc false
  use ExGram.Middleware

  alias AnyTalker.Antispam

  def call(context, _options) do
    case context.extra.chat do
      %{antispam: true} -> do_call(context.update.message, context)
      _error -> context
    end
  end

  defp do_call(%{new_chat_members: new_chat_members} = message, context) when is_list(new_chat_members) do
    bot_id = context.bot_info.id

    new_chat_members
    |> Enum.reject(&(&1.id == bot_id))
    |> Enum.each(&Antispam.create_captcha(&1.id, &1.first_name, message.chat.id, message.message_id))

    halt(context)
  end

  defp do_call(%{left_chat_member: left_chat_member} = message, context) when is_map(left_chat_member) do
    captcha = Antispam.get_captcha(left_chat_member.id, message.chat.id)

    if captcha.status in ~w[failed timed_out]a do
      ExGram.delete_message(message.chat.id, message.message_id, bot: AnyTalkerBot.bot())
    end

    halt(context)
  end

  defp do_call(message, context) do
    if captcha = Antispam.get_captcha(message.from.id, message.chat.id) do
      Antispam.try_resolve_captcha(captcha, message.text, message.message_id)
      halt(context)
    else
      context
    end
  end
end
