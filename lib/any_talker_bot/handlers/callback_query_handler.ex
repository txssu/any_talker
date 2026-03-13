defmodule AnyTalkerBot.Handlers.CallbackQueryHandler do
  @moduledoc false

  alias AnyTalkerBot.Reply

  def execute(reply, {:callback_query, %{data: "rss_news:" <> _rest}}) do
    AnyTalkerBot.RssPaginationHandler.call(reply)
  end

  def execute(reply, {:callback_query, %{data: "rss_read:" <> _rest}}) do
    AnyTalkerBot.RssMarkReadHandler.call(reply)
  end

  def execute(reply, {:callback_query, %{data: "counter-" <> _rest}}) do
    AnyTalkerBot.NikitaCounterAnswerHandler.call(reply)
  end

  def execute(reply, {:callback_query, _query}) do
    Reply.halt(reply)
  end
end
