defmodule AnyTalkerBot.Dispatcher do
  @moduledoc false
  use ExGram.Bot,
    name: :any_talker,
    setup_commands: false

  alias AnyTalkerBot.Handlers
  alias AnyTalkerBot.Middleware.IgnoreUsername
  alias AnyTalkerBot.Reply

  command("privacy")
  command("ask")
  command("ask_detailed")
  command("ban")
  command("buy_pro")
  command("que_pro")

  # ExGram calls extract_info/1 (text → {:command, name, msg}) BEFORE our build_reply pipeline runs.
  # IgnoreUsername in @middleware_pipeline is therefore too late to affect routing:
  # /privacy@BotUsername would reach CommandHandler as {:command, "privacy@BotUsername", msg}
  # and fall through to the unknown-command clause.
  # Registering it here ensures it runs in ExGram's own pipeline, before extract_info.
  middleware(IgnoreUsername)

  @middleware_pipeline [
    AnyTalkerBot.AddTelemetryDataMiddleware,
    AnyTalkerBot.SaveUpdateMiddleware,
    AnyTalkerBot.CaptionToTextMiddleware,
    IgnoreUsername,
    AnyTalkerBot.LoadDataMiddleware,
    AnyTalkerBot.AntispamMiddleware,
    AnyTalkerBot.IgnoreForwardedCommandsMiddleware
  ]

  def bot, do: :any_talker

  def handle(message, context) do
    reply = build_reply(message, context)

    Reply.execute(reply)

    now = :os.system_time()

    :telemetry.execute([:any_talker, :bot], %{handle_time: now - reply.context.extra.received_at}, %{
      message: message,
      context: reply.context
    })

    context
  end

  def build_reply(message, context) do
    context
    |> sync_message_from_command(message)
    |> run_middlewares()
    |> Reply.new()
    |> execute_command(message)
  end

  defp sync_message_from_command(context, {:command, _name, cmd_message}) do
    %{context | update: %{context.update | message: cmd_message}}
  end

  defp sync_message_from_command(context, _message), do: context

  defp run_middlewares(context) do
    Enum.reduce_while(@middleware_pipeline, context, fn middleware, ctx ->
      ctx = middleware.call(ctx, [])
      if ctx.middleware_halted, do: {:halt, ctx}, else: {:cont, ctx}
    end)
  end

  defp execute_command(%{context: %{middleware_halted: true} = context} = reply, _message) do
    if middleware_reply = context.extra[:middleware_reply] do
      middleware_reply
    else
      Reply.halt(reply)
    end
  end

  defp execute_command(reply, {:command, _name, _msg} = message), do: Handlers.CommandHandler.execute(reply, message)

  defp execute_command(reply, {:inline_query, _query} = message),
    do: Handlers.InlineQueryHandler.execute(reply, message)

  defp execute_command(reply, {:callback_query, _query} = message),
    do: Handlers.CallbackQueryHandler.execute(reply, message)

  defp execute_command(reply, {:update, _data} = message), do: Handlers.PaymentHandler.execute(reply, message)
  defp execute_command(reply, {:text, _text, _msg} = message), do: Handlers.TextHandler.execute(reply, message)
  defp execute_command(reply, _message), do: Reply.halt(reply)
end
