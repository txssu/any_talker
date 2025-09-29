defmodule AnyTalkerBot.ProInfoCommand do
  @moduledoc """
  Handles command for displaying detailed PRO subscription information.
  """

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.Subscription
  alias AnyTalkerBot.Reply

  @doc """
  Executes command by showing detailed PRO subscription information.
  """
  def call(%Reply{context: %{extra: %{user: user}}} = reply) do
    case Accounts.get_current_subscription(user) do
      %Subscription{} = sub ->
        Reply.send_message(reply, subscription_info_message(sub), for_dm: true)

      nil ->
        Reply.send_message(reply, no_subscription_message(), for_dm: true)
    end
  end

  defp subscription_info_message(%Subscription{expires_at: expires_at}) do
    expires_text = format_date(expires_at)

    """
    🚀 Ваша подписка PRO активна!

    ⏰ Действует до: #{expires_text}

    🔥 Доступные возможности:
    • Существенно больше запросов
    • Минимальные паузы после достижения лимита
    • Приоритет в обработке
    • Возможность делать запросы в любом чате и даже в личных сообщениях

    💎 Стоимость продления: 100 рублей

    Для покупки или продления используйте команду /buy_pro
    Спасибо за поддержку! 🙏
    """
  end

  defp no_subscription_message do
    """
    ❌ У вас нет активной подписки PRO

    🔥 Что дает подписка PRO:
    • Существенно больше запросов
    • Минимальные паузы после достижения лимита
    • Приоритет в обработке
    • Возможность делать запросы в любом чате и даже в личных сообщениях

    💎 Стоимость: 100 рублей

    Для покупки используйте команду /buy_pro
    """
  end

  defp format_date(nil), do: "бессрочно"

  defp format_date(%DateTime{} = datetime) do
    datetime
    |> DateTime.shift_zone!("Asia/Yekaterinburg")
    |> Calendar.strftime("%d.%m.%Y в %H:%M ЕКБ")
  end
end
