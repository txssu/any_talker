defmodule AnyTalkerBot.TextProcessor do
  @moduledoc """
  Utilities for processing text messages.
  """

  @doc """
  Extracts slash commands from text, ignoring URLs.

  Looks for patterns that start with "/" followed by English letters,
  digits and underscores, but not when they are part of URLs.

  ## Examples

      iex> AnyTalkerBot.TextProcessor.extract_slash_command("Всем привет, ищем junior/Middle разработчика")
      "/Middle"

      iex> AnyTalkerBot.TextProcessor.extract_slash_command("Нет команд здесь")
      nil

      iex> AnyTalkerBot.TextProcessor.extract_slash_command("Тест /test_123 команда")
      "/test_123"

      iex> AnyTalkerBot.TextProcessor.extract_slash_command("Команда /Upper подходит")
      "/Upper"

      iex> AnyTalkerBot.TextProcessor.extract_slash_command("Ссылка https://example.com/path игнорируется")
      nil
  """
  def extract_slash_command(text) when is_binary(text) do
    # First remove all URLs from the text
    text_without_urls = remove_urls(text)

    # Pattern: / followed by one or more English letters, digits, or underscores
    regex = ~r/\/([a-zA-Z0-9_]+)/

    case Regex.run(regex, text_without_urls) do
      [full_match, _command_part] -> full_match
      nil -> nil
    end
  end

  def extract_slash_command(_non_binary), do: nil

  defp remove_urls(text) do
    # Pattern to match URLs (http, https, ftp, etc.)
    url_regex = ~r/https?:\/\/[^\s]+|ftp:\/\/[^\s]+|www\.[^\s]+/i
    Regex.replace(url_regex, text, "")
  end
end
