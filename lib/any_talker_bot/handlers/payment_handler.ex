defmodule AnyTalkerBot.Handlers.PaymentHandler do
  @moduledoc false

  alias AnyTalkerBot.Reply

  def execute(reply, {:update, %{pre_checkout_query: %ExGram.Model.PreCheckoutQuery{invoice_payload: "subs:pro"}}}) do
    AnyTalkerBot.BuyProCommand.handle_pre_checkout(reply)
  end

  def execute(reply, _message) do
    Reply.halt(reply)
  end
end
