defmodule AnyTalkerBot.Dispatcher do
  @moduledoc false
  use ExGram.Bot,
    name: :any_talker,
    setup_commands: true

  alias AnyTalkerBot.Reply

  command("privacy", description: "Политика конфиденциальности")
  command("ask", description: "Задать вопрос мудрецу")
  command("v", description: "Версия бота")

  middleware(AnyTalkerBot.AddTelemetryDataMiddleware)
  middleware(AnyTalkerBot.SaveUpdateMiddleware)
  middleware(AnyTalkerBot.CaptionToTextMiddleware)
  middleware(ExGram.Middleware.IgnoreUsername)
  middleware(AnyTalkerBot.LoadDataMiddleware)
  middleware(AnyTalkerBot.AntispamMiddleware)

  @spec bot() :: :any_talker
  def bot, do: :any_talker

  @spec handle(ExGram.Dispatcher.parsed_message(), ExGram.Cnt.t()) :: ExGram.Cnt.t()
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

  defp execute_command(reply, {:command, :v, _msg}) do
    AnyTalkerBot.VCommand.call(reply)
  end

  # Fast ban @DickGrowerBot
  # Move to Antispam in future
  defp execute_command(%{context: %{update: %{message: %{via_bot: %{id: 6_465_471_545}} = message}}} = reply, _msg) do
    ExGram.delete_message(message.chat.id, message.message_id, bot: bot())
    %{reply | halt: true}
  end

  defp execute_command(reply, _msg) do
    %{reply | halt: true}
  end
end
