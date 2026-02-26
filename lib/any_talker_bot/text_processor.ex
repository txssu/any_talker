defmodule AnyTalkerBot.TextProcessor do
  @moduledoc """
  Utilities for processing text messages.
  """

  alias AnyTalkerBot.Reply
  alias ExGram.Model.Message

  @doc """
  Processes text message and returns a Reply.

  Handles (in order of priority):
  1. HTTP status codes: returns Reply with http.cat link as reply (ignores text containing "http.cat")
  2. Slash commands: sends message (only if no HTTP code found)
  """
  def process(%Reply{} = reply) do
    %Message{} = message = Reply.message(reply)
    text = message.text

    http_code = if String.contains?(text, "http.cat"), do: nil, else: extract_http_code(text)

    case {http_code, extract_slash_command(text, message)} do
      {code, _command} when is_integer(code) ->
        Reply.send_message(reply, "https://http.cat/#{code}", as_reply?: true)

      {nil, command} when is_binary(command) ->
        Reply.send_message(reply, command)

      {nil, nil} ->
        Reply.halt(reply)
    end
  end

  @http_codes MapSet.new([
                101,
                102,
                103,
                201,
                202,
                203,
                204,
                205,
                206,
                207,
                208,
                214,
                226,
                301,
                302,
                303,
                304,
                305,
                307,
                308,
                401,
                402,
                403,
                404,
                405,
                406,
                407,
                408,
                409,
                410,
                411,
                412,
                413,
                414,
                415,
                416,
                417,
                418,
                419,
                420,
                421,
                422,
                423,
                424,
                425,
                426,
                428,
                429,
                431,
                444,
                450,
                451,
                495,
                496,
                497,
                498,
                499,
                501,
                502,
                503,
                504,
                506,
                507,
                508,
                509,
                510,
                511,
                521,
                522,
                523,
                525,
                530,
                599
              ])

  @doc """
  Extracts an HTTP status code from text if it exists.

  Looks for numbers that are not surrounded by other digits.
  Letters around the code are allowed.

  ## Examples

      iex> AnyTalkerBot.TextProcessor.extract_http_code("error 404 not found")
      404

      iex> AnyTalkerBot.TextProcessor.extract_http_code("got a 500!")
      500

      iex> AnyTalkerBot.TextProcessor.extract_http_code("ф404ф")
      404

      iex> AnyTalkerBot.TextProcessor.extract_http_code("4041")
      nil

      iex> AnyTalkerBot.TextProcessor.extract_http_code("no codes here")
      nil
  """
  def extract_http_code(text) when is_binary(text) do
    ~r/(?:^|[^\d])(\d+)(?:[^\d]|$)/
    |> Regex.scan(text, capture: :all_but_first)
    |> List.flatten()
    |> Enum.find_value(&parse_http_code/1)
  end

  def extract_http_code(_non_binary), do: nil

  defp parse_http_code(num_str) do
    with {num, ""} <- Integer.parse(num_str),
         true <- MapSet.member?(@http_codes, num) do
      num
    else
      _other -> nil
    end
  end

  @doc """
  Extracts the first bot command from message entities.

  Uses Telegram's entities with type "bot_command" and extracts
  the command text using offset and length.

  Returns nil if no bot_command entity is found.
  """
  def extract_slash_command(text, %{entities: entities}) when is_binary(text) and is_list(entities) do
    case Enum.find(entities, &(&1.type == "bot_command")) do
      %{offset: offset, length: length} -> String.slice(text, offset, length)
      nil -> nil
    end
  end

  def extract_slash_command(_text, _message), do: nil
end
