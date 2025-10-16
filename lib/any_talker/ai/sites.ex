defmodule AnyTalker.AI.Sites do
  @moduledoc """
  Context for fetching and processing website content.

  This module provides a unified interface for fetching web pages and processing
  their content. It automatically selects the appropriate processor based on URL patterns
  and domains.

  ## Processors

  - `AnyTalker.AI.Sites.OpennetArticles` - For opennet.ru articles (/opennews/art.shtml)
  - `AnyTalker.AI.Sites.Opennet` - For *.opennet.ru domains (KOI8-R decoding)
  - `AnyTalker.AI.Sites.Default` - For all other websites (HTML to markdown)

  Processors are checked in order. The first matching processor is used.
  """

  alias AnyTalker.AI.Sites.Client
  alias AnyTalker.AI.Sites.Default
  alias AnyTalker.AI.Sites.Opennet
  alias AnyTalker.AI.Sites.OpennetArticles

  @processors [
    OpennetArticles,
    Opennet,
    Default
  ]

  @doc """
  Fetches and processes content from the given URL.

  The function automatically selects the appropriate processor by checking each
  processor's match?/1 function in order. The first matching processor is used.

  ## Examples

      iex> Sites.get("https://example.com")
      {:ok, markdown_content}

      iex> Sites.get("https://www.opennet.ru/opennews/art.shtml?num=12345")
      {:ok, article_text}

      iex> Sites.get("https://opennet.ru/news")
      {:ok, decoded_html}

      iex> Sites.get("https://invalid-url")
      {:error, reason}

  """
  def get(url) do
    with {:ok, response} <- Client.get(url) do
      processor = select_processor(url)
      processor.process(response)
    end
  end

  defp select_processor(url) do
    uri = URI.parse(url)

    Enum.find(@processors, Default, fn processor ->
      processor.match?(uri)
    end)
  end
end
