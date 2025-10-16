defmodule AnyTalker.AI.Sites.Opennet do
  @moduledoc """
  Processor for opennet.ru. Handles KOI8-R charset decoding only.

  Matches all *.opennet.ru domains.
  """

  @behaviour AnyTalker.AI.Sites.Processor

  alias AnyTalker.AI.Sites.Processor

  @impl Processor
  def match?(%URI{host: host}) do
    host == "opennet.ru" or String.ends_with?(host || "", ".opennet.ru")
  end

  @impl Processor
  def process(%Tesla.Env{} = response) do
    charset =
      response
      |> Tesla.get_header("content-type")
      |> extract_charset()

    decoded_body = decode_charset(charset, response.body)

    {:ok, decoded_body}
  end

  defp extract_charset(nil), do: nil

  defp extract_charset(content_type) do
    content_type
    |> String.downcase()
    |> String.split(";")
    |> Enum.find_value(fn part ->
      case String.trim(part) do
        "charset=" <> charset -> String.trim(charset)
        _other -> nil
      end
    end)
  end

  defp decode_charset(nil, body), do: body

  defp decode_charset(charset, body) do
    case Map.get(charset_mappings(), charset) do
      nil ->
        body

      encoding ->
        case Codepagex.to_string(body, encoding) do
          {:ok, decoded} -> decoded
          _error -> body
        end
    end
  end

  defp charset_mappings do
    %{
      "koi8-r" => :"VENDORS/MISC/KOI8-R"
    }
  end
end
