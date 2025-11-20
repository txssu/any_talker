defmodule AnyTalkerBot.BuyProCommand do
  @moduledoc """
  Handles command for purchasing premium subscriptions.
  """

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.Subscription
  alias AnyTalker.Currency
  alias AnyTalkerBot.Reply
  alias ExGram.Model.LabeledPrice

  require Logger

  @pro_payload "subs:pro"

  @doc """
  Executes command by sending a payment invoice.
  """
  def call(%Reply{} = reply) do
    user = reply.context.extra.user

    case Accounts.get_current_subscription(user) do
      %Subscription{} = sub ->
        Reply.send_message(reply, already_subscribed_message(sub), for_dm: true)

      nil ->
        provider_data = %{
          receipt: %{
            items: [
              %{
                description: "PRO подписка на месяц",
                quantity: "1.00",
                amount: %{
                  value: "100.00",
                  currency: "RUB"
                },
                vat_code: 1
              }
            ]
          }
        }

        Reply.send_invoice(
          reply,
          "Подписка PRO 🚀",
          description(),
          @pro_payload,
          "RUB",
          [
            %LabeledPrice{label: "PRO подписка на месяц", amount: Currency.rub(100)}
          ],
          for_dm: true,
          provider_token: AnyTalkerBot.Config.payment_provider_token(),
          provider_data: Jason.encode(provider_data),
          need_email: true,
          send_email_to_provider: true
        )
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
        Reply.answer_pre_checkout_query(
          reply,
          query.id,
          false,
          error_message: already_subscribed_message(sub)
        )

      nil ->
        Reply.answer_pre_checkout_query(reply, query.id, true)
    end
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
        Reply.send_message(reply, activation_success_message(sub), for_dm: true)

      {:error, error} ->
        log_activation_error(user.id, error)
        Reply.send_message(reply, activation_error_message(), for_dm: true)
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
    Logger.error("Failed to activate PRO subscription for user", details: %{user_id: user_id, error: error})
  end

  defp format_date(nil), do: "бессрочно"

  defp format_date(%DateTime{} = datetime) do
    datetime
    |> DateTime.shift_zone!("Asia/Yekaterinburg")
    |> Calendar.strftime("%d.%m.%Y в %H:%M МСК")
  end

  defp description do
    """
    🔥 Подписка PRO: больше запросов, приоритет в обработке.

    Подробности в /que_pro
    """
  end
end
