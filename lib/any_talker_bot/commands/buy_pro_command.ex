defmodule AnyTalkerBot.BuyProCommand do
  @moduledoc """
  Handles command for purchasing premium subscriptions.
  """

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.Subscription
  alias AnyTalker.Currency
  alias ExGram.Model.LabeledPrice

  require Logger

  @pro_payload "subs:pro"

  @doc """
  Executes command by sending a payment invoice.
  """
  def call(%{context: %{update: %{message: msg}}} = reply) do
    user = reply.context.extra.user

    case Accounts.get_current_subscription(user) do
      %Subscription{} = sub ->
        %{reply | text: already_subscribed_message(sub), for_dm: true}

      nil ->
        send_invoice_or_error(reply, msg.chat.id)
    end
  end

  @doc """
  Handles pre-checkout query for PRO subscription payments.
  """
  def handle_pre_checkout(
        %{context: %{update: %{pre_checkout_query: %{invoice_payload: @pro_payload} = query}}} = reply
      ) do
    user = Accounts.get_user(query.from.id)

    case Accounts.get_current_subscription(user) do
      %Subscription{} = sub ->
        ExGram.answer_pre_checkout_query!(query.id, false,
          bot: AnyTalkerBot.bot(),
          error_message: already_subscribed_message(sub)
        )

      nil ->
        ExGram.answer_pre_checkout_query!(query.id, true, bot: AnyTalkerBot.bot())
    end

    %{reply | halt: true}
  end

  def handle_pre_checkout(reply), do: reply

  @doc """
  Handles successful payment for PRO subscription.
  """
  def handle_successful_payment(
        %{context: %{update: %{message: %{successful_payment: %{invoice_payload: @pro_payload}}}}} = reply
      ) do
    user = reply.context.extra.user

    case Accounts.activate_pro_subscription(user) do
      {:ok, sub} ->
        %{reply | text: activation_success_message(sub), for_dm: true}

      {:error, error} ->
        log_activation_error(user.id, error)
        %{reply | text: activation_error_message(), for_dm: true}
    end
  end

  def handle_successful_payment(reply), do: reply

  defp already_subscribed_message(%Subscription{expires_at: expires_at}) do
    expires_text = format_date(expires_at)

    """
    У вас уже есть активная подписка PRO!

    Ваша подписка действует до: #{expires_text}

    Спасибо за поддержку! 🚀
    """
  end

  defp send_invoice_or_error(reply, chat_id) do
    case send_invoice(chat_id) do
      {:ok, _msg} ->
        %{reply | halt: true, for_dm: true}

      {:error, error} ->
        Logger.error("Can't send invoice.", error_details: error)
        %{reply | text: "Что-то не работает, попробуй позже", for_dm: true}
    end
  end

  defp activation_success_message(%Subscription{expires_at: expires_at}) do
    expires_text = format_date(expires_at)

    """
    🎉 Поздравляем! Подписка PRO активирована!

    Ваша подписка действует до: #{expires_text}

    Спасибо за поддержку! 🚀
    """
  end

  defp activation_error_message do
    """
    😔 Произошла ошибка при активации подписки.

    Обратитесь в поддержку, мы обязательно поможем!
    """
  end

  defp log_activation_error(user_id, error) do
    Logger.error("Failed to activate PRO subscription for user #{user_id}", error_details: error)
  end

  defp format_date(nil), do: "бессрочно"

  defp format_date(%DateTime{} = datetime) do
    datetime
    |> DateTime.shift_zone!("Asia/Yekaterinburg")
    |> Calendar.strftime("%d.%m.%Y в %H:%M МСК")
  end

  defp send_invoice(chat_id) do
    ExGram.send_invoice(
      chat_id,
      "Подписка PRO 🚀",
      description(),
      @pro_payload,
      "RUB",
      [
        %LabeledPrice{label: "PRO доступ", amount: Currency.rub(100)}
      ],
      bot: AnyTalkerBot.bot(),
      provider_token: AnyTalkerBot.Config.payment_provider_token()
    )
  end

  defp description do
    """
    🔥 Подписка PRO: больше запросов, приоритет в обработке.

    Подробности в /que_pro
    """
  end
end
