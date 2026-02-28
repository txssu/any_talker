defmodule AnyTalkerBot.InlineHandlers.AskInlineHandler do
  @moduledoc false

  alias AnyTalker.Accounts
  alias AnyTalker.AI.Envelope.Context
  alias AnyTalker.AI.Envelope.Source
  alias AnyTalker.AI.Generation
  alias AnyTalker.Settings
  alias AnyTalkerBot.HtmlUtils
  alias AnyTalkerBot.Reply
  alias AnyTalkerBot.Shared.Ask
  alias ExGram.Model.ChosenInlineResult
  alias ExGram.Model.InlineKeyboardButton
  alias ExGram.Model.InlineKeyboardMarkup
  alias ExGram.Model.InlineQueryResultArticle
  alias ExGram.Model.InputTextMessageContent

  require Logger

  def handle_inline_query(reply, query) do
    text = String.trim(query.query)
    text_html = HtmlUtils.escape_html(text)

    result = %InlineQueryResultArticle{
      type: "article",
      id: "ask",
      title: "Спросить AI",
      description: String.slice(text, 0, 100),
      input_message_content: %InputTextMessageContent{
        message_text: "<blockquote>#{text_html}</blockquote>",
        parse_mode: "HTML"
      },
      reply_markup: %InlineKeyboardMarkup{
        inline_keyboard: [[%InlineKeyboardButton{text: "⏳", callback_data: "noop"}]]
      }
    }

    Reply.answer_inline_query(reply, query.id, [result], cache_time: 0, is_personal: true)
  end

  def handle_chosen_inline_result(reply, %ChosenInlineResult{inline_message_id: nil}), do: Reply.halt(reply)

  def handle_chosen_inline_result(reply, %ChosenInlineResult{} = result) do
    {:ok, user} =
      result.from
      |> Map.from_struct()
      |> Accounts.upsert_user(~w[username first_name last_name]a)

    user_with_sub = Accounts.preload_current_subscription(user)
    config = Settings.get_full_chat_config(nil)

    with :ok <- Ask.validate_not_banned(user_with_sub),
         :ok <- Ask.validate_pro(user_with_sub),
         :ok <- Ask.validate_rate_limit(user_with_sub, config) do
      reply_inline_ai(reply, result, user_with_sub, config)
    else
      {:error, :banned} ->
        Reply.halt(reply)

      {:error, :not_pro} ->
        Reply.edit_inline_message(
          reply,
          result.inline_message_id,
          inline_reply_text(
            result.query,
            "Inline-режим доступен только с PRO-подпиской.\n/que_pro — узнать подробнее."
          ),
          parse_mode: "HTML"
        )

      {:error, :rate_limit, time_left_ms} ->
        text = "Ты выжал лимит.\nСледующая попытка будет доступна через #{Ask.format_time(time_left_ms)}."

        Reply.edit_inline_message(reply, result.inline_message_id, inline_reply_text(result.query, text),
          parse_mode: "HTML"
        )
    end
  end

  defp reply_inline_ai(reply, result, user_with_sub, config) do
    envelope = Source.to_envelope(result, %Context{author: user_with_sub, chat: config})

    case AnyTalker.AI.request(envelope) do
      {:ok, %Generation{} = gen} ->
        Ask.consume_tokens(user_with_sub, config, gen.response)

        text =
          gen.response.data.content
          |> HtmlUtils.escape_html_preserving_tags()
          |> Ask.replace_keywords()

        Reply.edit_inline_message(reply, result.inline_message_id, inline_reply_text(result.query, text),
          parse_mode: "HTML",
          reply_markup: %InlineKeyboardMarkup{inline_keyboard: []}
        )

      {:error, reason} ->
        Logger.error("AI inline request failed", details: %{reason: reason})

        Reply.edit_inline_message(reply, result.inline_message_id, inline_reply_text(result.query, "Да не"),
          parse_mode: "HTML"
        )
    end
  end

  defp inline_reply_text(query, text) do
    "<blockquote>#{HtmlUtils.escape_html(query)}</blockquote>\n#{text}"
  end
end
