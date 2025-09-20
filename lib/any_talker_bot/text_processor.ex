defmodule AnyTalkerBot.TextProcessor do
  @moduledoc """
  Utilities for processing text messages.
  """

  @doc """
  Extracts slash commands from text.

  Looks for patterns that start with "/" followed by English letters,
  digits and underscores.

  ## Examples

      iex> AnyTalkerBot.TextProcessor.extract_slash_command("Всем привет, ищем junior/Middle разработчика")
      "/Middle"

      iex> AnyTalkerBot.TextProcessor.extract_slash_command("Нет команд здесь")
      nil

      iex> AnyTalkerBot.TextProcessor.extract_slash_command("Тест /test_123 команда")
      "/test_123"

      iex> AnyTalkerBot.TextProcessor.extract_slash_command("Команда /Upper подходит")
      "/Upper"
  """
  def extract_slash_command(text) when is_binary(text) do
    # Pattern: / followed by one or more English letters, digits, or underscores
    regex = ~r/\/([a-zA-Z0-9_]+)/

    case Regex.run(regex, text) do
      [full_match, _command_part] -> full_match
      nil -> nil
    end
  end

  def extract_slash_command(_non_binary), do: nil
end
