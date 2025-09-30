defmodule AnyTalkerBot.Reply.CallbackQuery do
  @moduledoc """
  A callback query action for Reply that answers callback queries in Telegram.

  This module handles answering callback queries with optional text, alerts, and URLs.

  ## Fields

  - `callback_query_id` - The callback query ID to answer
  - `text` - Text of the notification. If not specified, nothing will be shown to the user
  - `show_alert` - If `true`, an alert will be shown by the client instead of a notification at the top of the chat screen
  - `url` - URL that will be opened by the user's client
  - `cache_time` - The maximum amount of time in seconds that the result may be cached client-side

  ## Example

      Reply.CallbackQuery.new(callback_query_id)
  """

  @behaviour AnyTalkerBot.Reply.Action

  alias AnyTalkerBot.Reply

  require Logger

  defstruct callback_query_id: nil,
            text: nil,
            show_alert: nil,
            url: nil,
            cache_time: nil

  @doc """
  Creates a new CallbackQuery with the given callback_query_id.

  ## Example

      Reply.CallbackQuery.new("12345")
  """
  def new(callback_query_id) when is_binary(callback_query_id) do
    %__MODULE__{callback_query_id: callback_query_id}
  end

  @impl Reply.Action
  def execute(%Reply{action: %__MODULE__{} = callback_query}) do
    options = build_options(callback_query)

    case ExGram.answer_callback_query(callback_query.callback_query_id, options) do
      {:ok, result} ->
        {:ok, result}

      {:error, error} ->
        Logger.error("Error answering callback query: #{inspect(error)}")
        {:error, error}
    end
  end

  defp build_options(%__MODULE__{} = callback_query) do
    Enum.reject(
      [
        bot: AnyTalkerBot.Dispatcher.bot(),
        text: callback_query.text,
        show_alert: callback_query.show_alert,
        url: callback_query.url,
        cache_time: callback_query.cache_time
      ],
      fn {_k, v} -> is_nil(v) end
    )
  end
end
