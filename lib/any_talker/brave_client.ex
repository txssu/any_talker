defmodule AnyTalker.BraveClient do
  @moduledoc false
  def search(query) do
    params = %{q: query, country: "RU", search_lang: "ru", ui_lang: "ru-RU", count: 5, result_filter: "web"}

    case Tesla.get(client(), "/web/search", query: params) do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp api_url do
    fetch_env(:api_url)
  end

  defp api_key do
    fetch_env(:api_key)
  end

  defp client do
    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, api_url()},
        {Tesla.Middleware.Headers, [{"x-subscription-token", api_key()}]},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Retry, delay: 1000, max_retries: 3, should_retry: &should_retry/3}
      ],
      Tesla.Adapter.Mint
    )
  end

  def should_retry(result, _env, _context) do
    case result do
      {:ok, %{status: 429}} -> true
      _otherwise -> false
    end
  end

  defp fetch_env(key) do
    :any_talker
    |> Application.get_env(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
