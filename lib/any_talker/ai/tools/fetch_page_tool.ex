defmodule AnyTalker.AI.FetchPageTool do
  @moduledoc false
  use AnyTalker.AI.Tool, type: :function

  alias AnyTalker.AI.Function
  alias AnyTalker.AI.SitesClient
  alias AnyTalker.AI.Tool

  require Logger

  @impl Tool
  def spec do
    %{
      type: "function",
      name: name(),
      description: "Fetch and extract content from a web page as Markdown",
      strict: true,
      parameters: %{
        additionalProperties: false,
        type: "object",
        properties: %{
          url: %{
            type: "string",
            description: "URL of the web page to fetch"
          }
        },
        required: ["url"]
      }
    }
  end

  @impl Function
  def name, do: "fetch_page"

  @impl Function
  def exec(%{"url" => url}, _context) do
    case SitesClient.get(url) do
      {:ok, markdown_content} ->
        markdown_content

      {:error, reason} ->
        Logger.error("Failed to fetch page", details: %{reason: reason, url: url})
        "Не удалось получить содержимое страницы"
    end
  end
end
