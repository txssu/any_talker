defmodule AnyTalker.AI.SearchTool do
  @moduledoc false
  use AnyTalker.AI.Tool, type: :function

  alias AnyTalker.AI.Function
  alias AnyTalker.AI.Tool
  alias AnyTalker.BraveClient

  require Logger

  @impl Tool
  def spec do
    %{
      type: "function",
      name: name(),
      description:
        "Search the web using Brave Search API. Use this tool when you don't know about the topic or need current information. If you need additional details from search results, use fetch_page tool with the URL.",
      strict: true,
      parameters: %{
        additionalProperties: false,
        type: "object",
        properties: %{
          query: %{
            type: "string",
            description: "Search query"
          }
        },
        required: ["query"]
      }
    }
  end

  @impl Function
  def name, do: "search"

  @impl Function
  def exec(%{"query" => query}, _context) do
    case BraveClient.search(query) do
      {:ok, body} ->
        filter_results(body)

      {:error, reason} ->
        Logger.error("Search failed: #{inspect(reason)}")
        "Поиск недоступен"
    end
  end

  defp filter_results(%{"web" => %{"results" => results}} = body) do
    filtered_results = Enum.map(results, &filter_result/1)

    %{
      "query" => body["query"]["original"],
      "results" => filtered_results
    }
  end

  defp filter_results(_body) do
    Logger.error("Unexpected search response format")
    "Поиск недоступен"
  end

  defp filter_result(result) do
    %{
      "title" => result["title"],
      "description" => result["description"],
      "url" => result["url"]
    }
  end
end
