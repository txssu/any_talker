defmodule AnyTalkerBot.Reply.PreCheckoutQuery do
  @moduledoc """
  A pre-checkout query action for Reply that answers pre-checkout queries in Telegram.

  This module handles answering pre-checkout queries to confirm or reject payment.

  ## Fields

  - `pre_checkout_query_id` - The pre-checkout query ID to answer
  - `ok` - Specify `true` if everything is alright and the bot is ready to proceed with the order, `false` otherwise
  - `error_message` - Required if `ok` is `false`. Error message in human readable form

  ## Example

      Reply.PreCheckoutQuery.new(pre_checkout_query_id, true)
  """

  @behaviour AnyTalkerBot.Reply.Action

  alias AnyTalkerBot.Reply

  require Logger

  defstruct pre_checkout_query_id: nil,
            ok: nil,
            error_message: nil

  @doc """
  Creates a new PreCheckoutQuery with the given pre_checkout_query_id and ok status.

  ## Example

      Reply.PreCheckoutQuery.new("12345", true)
  """
  def new(pre_checkout_query_id, ok) when is_binary(pre_checkout_query_id) and is_boolean(ok) do
    %__MODULE__{pre_checkout_query_id: pre_checkout_query_id, ok: ok}
  end

  @impl Reply.Action
  def execute(%Reply{action: %__MODULE__{} = pre_checkout_query}) do
    options = build_options(pre_checkout_query)

    case ExGram.answer_pre_checkout_query(
           pre_checkout_query.pre_checkout_query_id,
           pre_checkout_query.ok,
           options
         ) do
      {:ok, result} ->
        {:ok, result}

      {:error, error} ->
        Logger.error("Error answering pre-checkout query: #{inspect(error)}")
        {:error, error}
    end
  end

  defp build_options(%__MODULE__{} = pre_checkout_query) do
    Enum.reject(
      [
        bot: AnyTalkerBot.Dispatcher.bot(),
        error_message: pre_checkout_query.error_message
      ],
      fn {_k, v} -> is_nil(v) end
    )
  end
end
