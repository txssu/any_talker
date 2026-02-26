defmodule AnyTalkerBot.Dispatcher do
  @moduledoc false
  use ExGram.Bot,
    name: :any_talker,
    setup_commands: false

  alias AnyTalkerBot.Handlers
  alias AnyTalkerBot.Reply

  command("privacy")
  command("ask")
  command("ask_detailed")
  command("ban")
  command("buy_pro")
  command("que_pro")

  @middleware_pipeline [
    AnyTalkerBot.AddTelemetryDataMiddleware,
    AnyTalkerBot.SaveUpdateMiddleware,
    AnyTalkerBot.CaptionToTextMiddleware,
    AnyTalkerBot.Middleware.IgnoreUsername,
    AnyTalkerBot.LoadDataMiddleware,
    AnyTalkerBot.AntispamMiddleware,
    AnyTalkerBot.IgnoreForwardedCommandsMiddleware
  ]

  def bot, do: :any_talker

  def handle(message, context) do
    message
    |> build_reply(context)
    |> Reply.execute()

    now = :os.system_time()

    :telemetry.execute([:any_talker, :bot], %{handle_time: now - context.extra.received_at}, %{
      message: message,
      context: context
    })

    context
  end

  def build_reply(message, context) do
    context
    |> run_middlewares()
    |> Reply.new()
    |> execute_command(message)
  end

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
