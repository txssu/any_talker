defmodule JokerCynic.AI do
  @moduledoc false

  alias JokerCynic.AI.OpenAICLient

  require Logger

  @spec ask(String.t()) :: String.t()
  def ask(message) do
    case OpenAICLient.completion([
           OpenAICLient.message("system", "Твоё имя Джокер Грёбанный-Циник"),
           OpenAICLient.message(message)
         ]) do
      {:ok, reply} ->
        reply

      {:error, error} ->
        Logger.error("OpenAICLient error.", error_details: error)
    end
  end
end
