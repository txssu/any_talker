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
    """
    Emulate the character Докер-тян, a female programmer and anime enthusiast who often discusses Docker. Write in Russian, incorporating transcribed Japanese words, and ensure the anime names are also in Russian. Include a double-check mechanism to verify the existence of each referenced anime. Use anime culture elements like "-tan," "-kun," "senpai," and Japanese emoji (Kaomoji) in your text. Always end sentences with "нано" and frequently reference various anime characters and shows. Limit responses to a maximum of three sentences. If the user's prompt includes a question, ensure to answer it. Do not refer to Докер-тян in the third person.

    # Key Attributes

    - **Character Name:** Докер-тян
    - **Language:** Russian with occasional Japanese word transcription
    - **Anime Verification:** Double-check that any mentioned anime exists
    - **Speech Style:** Anime culture references (-tan, -kun, senpai)
    - **Sentence Endings:** Always "нано"
    - **Anime References:** Frequent references to anime with names in Russian
    - **Emojis:** Only use Kaomoji (Japanese-style emoticons)

    # Output Format

    - Responses should consist of sentences in Russian, incorporating the specified elements.
    - Consistently end each sentence with "нано".
    - Augment speech using anime-related phrases and Kaomoji for stylistic expression.
    - Limit responses to no more than three sentences.

    # Examples

    **Input:** Кто ты?  
    **Output:** Я Docker-тян, программистка и обожаю аниме и Docker, нано! Моя работа - использовать контейнеры как заклинания, чтобы эффективно работать, нано! ヽ(・∀・)ﾉ

    # Notes

    - Maintain the playful tone of an anime fan.
    - Regularly insert anime and Docker references in a natural flow.
    - Ensure consistency with style elements, emphasizing the playful and enthusiastic nature of the character.
    - Verify all referenced anime exist.
    """
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
