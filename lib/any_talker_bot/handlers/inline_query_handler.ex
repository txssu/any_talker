defmodule AnyTalkerBot.Handlers.InlineQueryHandler do
  @moduledoc false

  alias AnyTalkerBot.Reply

  @handlers [
    AnyTalkerBot.InlineHandlers.CurrencyInlineHandler,
    AnyTalkerBot.InlineHandlers.CleanUrlInlineHandler,
    AnyTalkerBot.InlineHandlers.AskInlineHandler
  ]

  def execute(reply, {:inline_query, query}) do
    query_text = String.trim(query.query)

    if query_text == "" do
      Reply.halt(reply)
    else
      results = collect_results(query_text, query)
      Reply.answer_inline_query(reply, query.id, results, cache_time: 0, is_personal: true)
    end
  end

  defp collect_results(query_text, query) do
    Enum.flat_map(@handlers, fn handler ->
      if handler.match?(query_text), do: handler.build_results(query), else: []
    end)
  end
end
