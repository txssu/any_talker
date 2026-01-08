defmodule AnyTalker.AI.Summarizer do
  @moduledoc """
  Summarizes long texts using AI.
  """

  alias AnyTalker.AI.Message
  alias AnyTalker.AI.OpenRouterClient
  alias AnyTalker.AI.Request
  alias AnyTalker.AI.Response

  @doc """
  Summarizes text using AI.

  ## Parameters

    * `text` - Text to summarize
    * `opts` - Options:
      * `:prompt` - Custom system prompt for summarization

  ## Examples

      iex> summarize("Long text...")
      {:ok, "Summary of the text..."}
  """
  @spec summarize(String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def summarize(text, opts \\ []) do
    system_prompt = Keyword.get(opts, :prompt, default_prompt())

    instructions = Message.new(nil, "system", system_prompt, nil)
    user_message = Message.new(nil, "user", text, nil)

    model_string = AnyTalker.GlobalConfig.get(:ask_model)
    models = String.split(model_string, " ", trim: true)

    request = %Request{
      models: models,
      messages: [user_message],
      instructions: instructions,
      tools: []
    }

    case OpenRouterClient.completions(request) do
      {:ok, %Response{data: %Response.TextOutput{content: content}}} ->
        {:ok, content}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp default_prompt do
    """
    Ты — помощник для создания кратких саммари текстов.

    Твоя задача: прочитать текст и создать структурированное саммари на русском языке.

    Требования к саммари:
    - Выдели основную тему и ключевые идеи
    - Перечисли главные тезисы и выводы
    - Сохрани важные детали, цифры, имена
    - Используй маркированные списки для структуры
    - Длина: 500-1500 символов

    Отвечай только саммари, без вступлений и пояснений.
    """
  end
end
