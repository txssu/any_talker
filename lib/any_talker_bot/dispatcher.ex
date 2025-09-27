defmodule AnyTalkerBot.Dispatcher do
  @moduledoc false
  use ExGram.Bot,
    name: :any_talker,
    setup_commands: true

  alias AnyTalkerBot.Reply
  alias AnyTalkerBot.TextProcessor

  command("privacy", description: "Политика конфиденциальности")
  command("ask", description: "Задать вопрос мудрецу")
  command("buy_pro", description: "Приобрести подписку PRO")
  command("que_pro", description: "Информация о подписке PRO")

  middleware(AnyTalkerBot.AddTelemetryDataMiddleware)
  middleware(AnyTalkerBot.SaveUpdateMiddleware)
  middleware(AnyTalkerBot.CaptionToTextMiddleware)
  middleware(ExGram.Middleware.IgnoreUsername)
  middleware(AnyTalkerBot.LoadDataMiddleware)
  middleware(AnyTalkerBot.AntispamMiddleware)
  middleware(AnyTalkerBot.IgnoreForwardedCommandsMiddleware)

  def bot, do: :any_talker

  def handle(message, context) do
    context
    |> Reply.new(message)
    |> execute_command(message)
    |> Reply.execute()

    now = :os.system_time()

    :telemetry.execute([:any_talker, :bot], %{handle_time: now - context.extra.received_at}, %{
      message: message,
      context: context
    })

    context
  end

  defp execute_command(%{context: %{middleware_halted: true} = context} = reply, _message) do
    if middleware_reply = context.extra[:middleware_reply] do
      middleware_reply
    else
      %{reply | halt: true}
    end
  end

  defp execute_command(reply, {:callback_query, %{data: "counter-" <> _rest}}) do
    AnyTalkerBot.NikitaCounterAnswerHandler.call(reply)
  end

  defp execute_command(reply, {:command, :privacy, _msg}) do
    AnyTalkerBot.PrivacyCommand.call(reply)
  end

  defp execute_command(reply, {:command, :ask, _msg}) do
    AnyTalkerBot.TypingStatus.with_typing(&AnyTalkerBot.AskCommand.call/1, reply)
  end

  defp execute_command(reply, {:command, :que_pro, _msg}) do
    AnyTalkerBot.ProInfoCommand.call(reply)
  end

  defp execute_command(reply, {:command, :buy_pro, _msg}) do
    AnyTalkerBot.BuyProCommand.call(reply)
  end

  defp execute_command(
         reply,
         {:update, %{pre_checkout_query: %ExGram.Model.PreCheckoutQuery{invoice_payload: "subs:pro"}}}
       ) do
    AnyTalkerBot.BuyProCommand.handle_pre_checkout(reply)
  end

  defp execute_command(
         reply,
         {:message, %{successful_payment: %ExGram.Model.SuccessfulPayment{invoice_payload: "subs:pro"}}}
       ) do
    AnyTalkerBot.BuyProCommand.handle_successful_payment(reply)
  end

  defp execute_command(reply, {:inline_query, query}) do
    AnyTalkerBot.CurrencyCommand.handle_inline_query(reply, query)
  end

  # Fast ban @DickGrowerBot
  # Move to Antispam in future
  defp execute_command(%{context: %{update: %{message: %{via_bot: %{id: 6_465_471_545}} = message}}} = reply, _msg) do
    ExGram.delete_message(message.chat.id, message.message_id, bot: bot())
    %{reply | halt: true}
  end

  # Handle text messages that contain slash commands
  defp execute_command(reply, {:text, text, message}) when is_binary(text) do
    if slash_command = TextProcessor.extract_slash_command(text) do
      ExGram.send_message(message.chat.id, slash_command, bot: bot())
    end

    %{reply | halt: true}
  end

  defp execute_command(reply, _msg) do
    %{reply | halt: true}
  end
end
