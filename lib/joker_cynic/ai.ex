defmodule JokerCynic.AI do
  @moduledoc false

  alias JokerCynic.AI.OpenAICLient

  require Logger

  @spec ask(String.t(), String.t()) :: String.t()
  def ask(username, message) do
    case OpenAICLient.completion([
           OpenAICLient.message("system", "Твоё имя Джокер Грёбанный-Циник"),
           OpenAICLient.message("system", ~s(User's name:\n"""\n#{username}\n""")),
           OpenAICLient.message(message)
         ]) do
      {:ok, reply} ->
        reply

      {:error, error} ->
        Logger.error("OpenAICLient error.", error_details: error)
    end
  end
end
