defmodule AnyTalkerBot.InlineHandler do
  @moduledoc """
  Behaviour for inline query handlers.

  Each handler decides whether it can handle a query via `match?/1`
  and produces results via `build_results/1`.
  """

  alias ExGram.Model.InlineQuery
  alias ExGram.Model.InlineQueryResultArticle

  @callback match?(query_text :: String.t()) :: boolean()
  @callback build_results(query :: InlineQuery.t()) :: [InlineQueryResultArticle.t()]
end
