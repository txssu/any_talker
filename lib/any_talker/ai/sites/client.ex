defmodule AnyTalker.AI.Sites.Client do
  @moduledoc """
  HTTP client for fetching web pages using Tesla.
  """

  @doc """
  Fetches a URL and returns the Tesla response.

  ## Examples

      iex> Client.get("https://example.com")
      {:ok, %Tesla.Env{status: 200, body: "..."}}

      iex> Client.get("https://invalid-url")
      {:error, reason}

  """
  def get(url) do
    Tesla.get(client(), url)
  end

  defp client do
    Tesla.client(
      [
        {Tesla.Middleware.FollowRedirects, max_redirects: 5},
        {Tesla.Middleware.Headers, [{"user-agent", user_agent()}]}
      ],
      Tesla.Adapter.Mint
    )
  end

  defp user_agent do
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0.1 Safari/605.1.15"
  end
end
