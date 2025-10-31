defmodule AnyTalkerBot.Dispatcher do
  @moduledoc false
  use ExGram.Bot,
    name: :any_talker,
    setup_commands: false

  alias AnyTalkerBot.Reply
  alias AnyTalkerBot.TextProcessor

  command("privacy")
  command("ask")
  command("buy_pro")
  command("que_pro")
  command("move")

  middleware(AnyTalkerBot.AddTelemetryDataMiddleware)
  middleware(AnyTalkerBot.SaveUpdateMiddleware)
  middleware(AnyTalkerBot.CaptionToTextMiddleware)
  middleware(AnyTalkerBot.Middleware.IgnoreUsername)
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
      Reply.halt(reply)
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

  defp execute_command(reply, {:command, :move, _msg}) do
    AnyTalkerBot.MoveCommand.call(reply)
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
    route_inline_query(reply, query)
  end

  # Fast ban @DickGrowerBot
  # Move to Antispam in future
  defp execute_command(%{context: %{update: %{message: %{via_bot: %{id: 6_465_471_545}} = message}}} = reply, _msg) do
    ExGram.delete_message(message.chat.id, message.message_id, bot: bot())
    Reply.halt(reply)
  end

  # Handle text messages that contain slash commands
  defp execute_command(reply, {:text, text, message}) when is_binary(text) do
    if slash_command = TextProcessor.extract_slash_command(text) do
      ExGram.send_message(message.chat.id, slash_command, bot: bot())
    end

    Reply.halt(reply)
  end

  defp execute_command(reply, _msg) do
    Reply.halt(reply)
  end

  defp route_inline_query(reply, query) do
    case detect_inline_query_type(query.query) do
      :empty ->
        send_combined_help(reply, query)

      :url ->
        AnyTalkerBot.EmbedLinkCommand.handle_inline_query(reply, query)

      :currency ->
        AnyTalkerBot.CurrencyCommand.handle_inline_query(reply, query)
    end
  end

  defp detect_inline_query_type(""), do: :empty

  defp detect_inline_query_type(query_text) when is_binary(query_text) do
    trimmed = String.trim(query_text)

    cond do
      trimmed == "" ->
        :empty

      String.contains?(trimmed, [".com", ".org", ".net", "http://", "https://"]) ->
        :url

      true ->
        :currency
    end
  end

  defp send_combined_help(reply, query) do
    alias ExGram.Model.InlineQueryResultArticle
    alias ExGram.Model.InputTextMessageContent

    currency_help = %InlineQueryResultArticle{
      type: "article",
      id: "currency_help",
      title: "Конвертация валют",
      description: "Формат: {from} {to} {amount}",
      input_message_content: %InputTextMessageContent{
        message_text: "Формат: {from} {to} {amount}\nПоддерживаются сокращения: k (тысячи), kk (миллионы)"
      }
    }

    embed_help = %InlineQueryResultArticle{
      type: "article",
      id: "embed_help",
      title: "Встроенные ссылки",
      description: "Конвертация ссылок в embedded версии",
      input_message_content: %InputTextMessageContent{
        message_text: "Вставьте ссылку для создания embedded превью."
      }
    }

    Reply.answer_inline_query(reply, query.id, [currency_help, embed_help])
  end
end
