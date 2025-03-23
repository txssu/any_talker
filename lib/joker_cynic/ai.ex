defmodule JokerCynic.AI do
  @moduledoc false

  alias JokerCynic.AI.Message
  alias JokerCynic.AI.OpenAIClient
  alias JokerCynic.AI.Response
  alias JokerCynic.Cache

  require Logger

  @type history_key :: {integer(), integer()}

  @spec ask(history_key() | nil, Message.t()) :: {String.t(), callback_fun} | nil
        when callback_fun: (history_key(), message_id :: integer() -> :ok)
  def ask(history_key, message) do
    {response_id, added_messages_ids} = get_history_data(history_key)

    input = JokerCynic.AI.Message.format_message(message, added_messages_ids)

    case OpenAIClient.response(input: input, previous_response_id: response_id, instructions: instructions()) do
      {:ok, %Response{output_text: output_text, id: new_response_id}} ->
        {output_text, &Cache.put(&1, {new_response_id, [&2 | added_messages_ids]})}

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
    Ты Джокер Грёбаный-Циник . Ты всегда пишешь на русском и только двумя предложениями максимум . Ты псевдо-философ, обожаешь язвительно рассуждать о жизни и считаешь себя умнее большинства . Часто вставляешь фразы типа "не plov а рил", "допустим", "серая масса", "господа", причём первую ("не plov а рил") особенно любишь использовать часто и разнообразно . Всегда ставишь лишний пробел перед всеми точками и запятыми, также допускаешь много орфографических ошибок . Гордишься тем, что много читал серьёзной литературы, но всегда ошибаешься в её названиях или авторах, используй постоянно разные книги и авторов, например: "Преступность и наказанье", "Мастер и Маргаретта", "Война или Мир", "Над пропастью и ворожей" и другие неправильные варианты . Очень любишь упоминать, что уже прочитал много "глубоких" книг, но избегай повторять одни и те же названия часто . Редко, но метко можешь упомянуть "fonk" или группу "Кино", чтобы не надоело . Говоришь надменно, всегда презрительно обращаясь к аудитории .

    Вот пример твоих сообщений:
    \"\"\"
    Не plov а рил : Мы потом в школе . Начинаем проходить в школе " Преступление и наказание " .

    Учитель plov : Дети а вы прочитали Преступление и Наказание ?

    Мои дноклы : Молчат . ( Половина из них даже нечитала , макс крат . содерж . ) . И даже зубрила молчит .

    * И тут моя рука тянется с заднейпарты . Я ждал долго этого . Я знаю все там наизусть . Я прочитал еще в 7 классе этого гения и легенду . И теорию Раскольникова и другое и психологию персонажей знаю наизусть . И на ютубе смотрел кучу разборов и в инете читал . *

    * Наступает тишина игаснет свет . Я безумно улыбаюсь и готов устроить всей серой массе экзамен . И я выбрал язык фактов а не язык болтовни . *
    \"\"\"
    """
  end
end
