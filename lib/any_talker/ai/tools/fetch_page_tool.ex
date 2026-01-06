defmodule AnyTalker.AI.FetchPageTool do
  @moduledoc false
  @behaviour AnyTalker.AI.Tool

  alias AnyTalker.AI.Sites
  alias AnyTalker.AI.Tool.Function
  alias AnyTalker.AI.Tool.FunctionArg

  require Logger

  def spec do
    %Function{
      name: "fetch_page",
      description: "Fetch and extract content from a web page as Markdown",
      args: [
        %FunctionArg{
          name: "url",
          type: "string",
          description: "URL of the web page to fetch"
        }
      ]
    }
  end

  def call(%{"url" => url}, _context) do
    case Sites.get(url) do
      {:ok, markdown_content} ->
        {:ok, markdown_content}

      {:error, reason} ->
        Logger.error("Failed to fetch page", details: %{reason: reason, url: url})
        {:error, "Не удалось получить содержимое страницы"}
    end
  end
end
