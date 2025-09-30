defmodule AnyTalkerBot.Reply.InlineQuery do
  @moduledoc """
  An inline query action for Reply that answers inline queries in Telegram.

  This module handles answering inline queries with results.

  ## Fields

  - `query_id` - The inline query ID to answer
  - `results` - List of inline query results to send
  - `cache_time` - The maximum amount of time in seconds that the result of the inline query may be cached on the server
  - `is_personal` - Pass True if results may be cached on the server side only for the user that sent the query
  - `next_offset` - Pass the offset that a client should send in the next query with the same text to receive more results
  - `button` - A button to be shown above inline query results

  ## Example

      Reply.InlineQuery.new(query_id, [result])
  """

  @behaviour AnyTalkerBot.Reply.Action

  alias AnyTalkerBot.Reply

  require Logger

  defstruct query_id: nil,
            results: [],
            cache_time: nil,
            is_personal: nil,
            next_offset: nil,
            button: nil

  @doc """
  Creates a new InlineQuery with the given query_id and results.

  ## Example

      Reply.InlineQuery.new("12345", [result])
  """
  def new(query_id, results) when is_binary(query_id) and is_list(results) do
    %__MODULE__{query_id: query_id, results: results}
  end

  @impl Reply.Action
  def execute(%Reply{action: %__MODULE__{} = inline_query}) do
    options = build_options(inline_query)

    case ExGram.answer_inline_query(inline_query.query_id, inline_query.results, options) do
      {:ok, result} ->
        {:ok, result}

      {:error, error} ->
        Logger.error("Error answering inline query: #{inspect(error)}")
        {:error, error}
    end
  end

  defp build_options(%__MODULE__{} = inline_query) do
    Enum.reject(
      [
        bot: AnyTalkerBot.Dispatcher.bot(),
        cache_time: inline_query.cache_time,
        is_personal: inline_query.is_personal,
        next_offset: inline_query.next_offset,
        button: inline_query.button
      ],
      fn {_k, v} -> is_nil(v) end
    )
  end
end
