defmodule AnyTalker.AI do
  @moduledoc false

  alias AnyTalker.AI.Message
  alias AnyTalker.AI.OpenAIClient
  alias AnyTalker.Cache
  alias AnyTalker.GlobalConfig

  require Logger

  @type history_key :: {integer(), integer()}

  @spec ask(history_key() | nil, Message.t()) :: {String.t(), callback_fun} | nil
        when callback_fun: (history_key(), message_id :: integer() -> :ok)
  def ask(history_key, message) do
    default_prompt = GlobalConfig.get(:ask_default_prompt)
    ask(history_key, message, default_prompt)
  end

  @spec ask(history_key() | nil, Message.t(), String.t()) :: {String.t(), callback_fun} | nil
        when callback_fun: (history_key(), message_id :: integer() -> :ok)
  def ask(history_key, message, prompt) do
    {response_id, added_messages_ids} = get_history_data(history_key)

    with {:ok, final_message} <- AnyTalker.AI.Attachments.download_message_image(message),
         input = Message.format_message(final_message, added_messages_ids),
         model = GlobalConfig.get(:ask_model),
         {:ok, response} <-
           OpenAIClient.response(
             input: input,
             previous_response_id: response_id,
             model: model,
             instructions: instructions(prompt)
           ) do
      hit_metrics(response)
      {response.output_text, &Cache.put(&1, {response.id, [&2 | added_messages_ids]})}
    else
      {:error, error} ->
        Logger.error("OpenAiClientError", error_details: error)
        nil
    end
  end

  defp get_history_data(history_key) do
    case Cache.get(history_key) do
      nil -> {nil, []}
      value -> value
    end
  end

  if Mix.env() == :prod do
    defp instructions(prompt) do
      today =
        "Etc/GMT+5"
        |> DateTime.now!()
        |> DateTime.to_date()
        |> Date.to_iso8601()

      "#{prompt}\n\n Today's date is: #{today}."
    end
  else
    defp instructions(_prompt) do
      "You are in a test environment."
    end
  end

  defp hit_metrics(response) do
    :telemetry.execute(
      [:any_talker, :bot, :ai],
      %{
        total_tokens: response.total_tokens
      },
      %{model: response.model}
    )

    :ok
  end
end
