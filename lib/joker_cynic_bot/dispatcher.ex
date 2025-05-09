defmodule JokerCynicBot.Dispatcher do
  @moduledoc false
  use ExGram.Bot,
    name: :joker_cynic,
    setup_commands: true

  alias JokerCynicBot.Reply

  command("privacy", description: "Политика конфиденциальности")
  command("ask", description: "Задать вопрос мудрецу")
  command("v", description: "Версия бота")

  middleware(JokerCynicBot.AddTelemetryDataMiddleware)
  middleware(JokerCynicBot.SaveUpdateMiddleware)
  middleware(JokerCynicBot.CaptionToTextMiddleware)
  middleware(ExGram.Middleware.IgnoreUsername)
  middleware(JokerCynicBot.LoadDataMiddleware)
  middleware(JokerCynicBot.AntispamMiddleware)

  @spec bot() :: :joker_cynic
  def bot, do: :joker_cynic

  @spec handle(ExGram.Dispatcher.parsed_message(), ExGram.Cnt.t()) :: ExGram.Cnt.t()
  def handle(message, context) do
    context
    |> Reply.new(message)
    |> execute_command(message)
    |> Reply.execute()

    now = :os.system_time()

    :telemetry.execute([:joker_cynic, :bot], %{handle_time: now - context.extra.received_at}, %{
      message: message,
      context: context
    })

    context
  end

  defp execute_command(%{context: %{middleware_halted: true} = context} = reply, _message) do
    if middleware_reply = context.extra[:middleware_reply] do
      middleware_reply
    else
      %Reply{reply | halt: true}
    end
  end

  defp execute_command(reply, {:callback_query, %{data: "counter-" <> _rest}}) do
    JokerCynicBot.NikitaCounterAnswerHandler.call(reply)
  end

  defp execute_command(reply, {:command, :privacy, _msg}) do
    JokerCynicBot.PrivacyCommand.call(reply)
  end

  defp execute_command(reply, {:command, :ask, _msg}) do
    JokerCynicBot.TypingStatus.with_typing(&JokerCynicBot.AskCommand.call/1, reply)
  end

  defp execute_command(reply, {:command, :v, _msg}) do
    JokerCynicBot.VCommand.call(reply)
  end

  # Fast ban @DickGrowerBot
  # Move to Antispam in future
  defp execute_command(%{context: %{update: %{message: %{via_bot: %{id: 6_465_471_545}} = message}}} = reply, _msg) do
    ExGram.delete_message(message.chat.id, message.message_id, bot: bot())
    %Reply{reply | halt: true}
  end

  defp execute_command(reply, _msg) do
    %Reply{reply | halt: true}
  end
end
