defmodule JokerCynicBot.TokenRedactor do
  @moduledoc false
  @behaviour LoggerJSON.Redactor

  @impl LoggerJSON.Redactor
  def redact("message", value, _options) do
    String.replace(value, JokerCynicBot.Token.value(), "[TOKEN]")
  end

  def redact(_key, value, _options) do
    value
  end
end
