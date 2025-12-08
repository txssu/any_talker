defmodule AnyTalkerBot.BuyProCommand do
  @moduledoc """
  Handles command for purchasing premium subscriptions.
  """

  alias AnyTalkerBot.Reply

  require Logger

  @pro_payload "subs:pro"

  @doc """
  Executes command by sending a payment invoice.
  """
  def call(%Reply{} = reply) do
    text = """
    Покупка и продление подписки временно приостановлены.
    """

    Reply.send_message(reply, text, for_dm: true)
  end

  @doc """
  Handles pre-checkout query for PRO subscription payments.
  """
  def handle_pre_checkout(
        %{context: %{update: %{pre_checkout_query: %{invoice_payload: @pro_payload} = query}}} = reply
      ) do
    Reply.answer_pre_checkout_query(reply, query.id, false,
      error_message: "Покупка и продление подписки временно приостановлены."
    )
  end

  def handle_pre_checkout(reply), do: reply
end
