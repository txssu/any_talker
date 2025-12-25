defmodule AnyTalker.AI.SearchTool do
  @moduledoc false
  @behaviour AnyTalker.AI.Tool

  alias AnyTalker.AI.Tool.Function
  alias AnyTalker.AI.Tool.FunctionArg
  alias AnyTalker.BraveClient

  require Logger

  def spec do
    %Function{
      name: "search",
      description:
        "Search the web using Brave Search API. Use this tool when you don't know about the topic or need current information. If you need additional details from search results, use fetch_page tool with the URL.",
      args: [
        %FunctionArg{
          name: "query",
          type: "string",
          description: "Search query"
        }
      ]
    }
  end

  def call(%{"query" => query}, _context) do
    case BraveClient.search(query) do
      {:ok, body} ->
        {:ok, filter_results(body)}

      {:error, reason} ->
        Logger.error("Search failed", details: %{reason: reason})
        {:error, "Поиск недоступен"}
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
