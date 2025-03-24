defmodule JokerCynic.AI do
  @moduledoc false

  alias JokerCynic.AI.Message
  alias JokerCynic.AI.OpenAIClient
  alias JokerCynic.Cache

  require Logger

  @type history_key :: {integer(), integer()}

  @spec ask(history_key() | nil, Message.t()) :: {String.t(), callback_fun} | nil
        when callback_fun: (history_key(), message_id :: integer() -> :ok)
  def ask(history_key, message) do
    {response_id, added_messages_ids} = get_history_data(history_key)

    input = JokerCynic.AI.Message.format_message(message, added_messages_ids)

    case OpenAIClient.response(input: input, previous_response_id: response_id, instructions: instructions()) do
      {:ok, response} ->
        hit_metrics(response)
        {response.output_text, &Cache.put(&1, {response.id, [&2 | added_messages_ids]})}

      {:error, _error} ->
        nil
    end
  end

  defp get_history_data(history_key) do
    case Cache.get(history_key) do
      nil -> {nil, []}
      value -> value
    end
  end

  defp instructions do
    :joker_cynic
    |> Application.get_env(__MODULE__)
    |> Keyword.fetch!(:instructions)
  end

  defp hit_metrics(response) do
    :telemetry.execute(
      [:joker_cynic, :bot, :ai],
      %{
        total_tokens: response.total_tokens
      },
      %{model: response.model}
    )

    :ok
  end
end
