defmodule AnyTalker.YouTube.Client do
  @moduledoc """
  Tesla-based HTTP client for YouTube InnerTube API and captions.
  """

  alias Tesla.Adapter.Mint
  alias Tesla.Middleware.Headers

  @innertube_api_base "https://www.youtube.com/youtubei/v1"
  @innertube_api_key "AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"

  @doc """
  Fetches data from InnerTube API endpoint.
  """
  def fetch_innertube(endpoint, payload, visitor_data) do
    headers = [
      {"Content-Type", "application/json"},
      {"Accept", "*/*"},
      {"X-Youtube-Client-Version", "2.20250222.10.00"},
      {"X-Youtube-Client-Name", "1"},
      {"X-Goog-Visitor-Id", visitor_data},
      {"Origin", "https://www.youtube.com"},
      {"Referer", "https://www.youtube.com/"}
    ]

    url = "#{endpoint}?key=#{@innertube_api_key}"
    client = innertube_client(headers)

    case Tesla.post(client, url, payload) do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{status: status}} -> {:error, "Request failed with status #{status}"}
      {:error, reason} -> {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  @doc """
  Fetches caption XML from YouTube.
  """
  def fetch_captions(caption_url, video_id) do
    headers = [
      {"Referer", "https://www.youtube.com/watch?v=#{video_id}"}
    ]

    client = caption_client(headers)

    case Tesla.get(client, caption_url) do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{status: status}} -> {:error, "Caption fetch failed: #{status}"}
      {:error, reason} -> {:error, "Caption fetch failed: #{inspect(reason)}"}
    end
  end

  defp innertube_client(headers) do
    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, @innertube_api_base},
        {Headers, headers},
        Tesla.Middleware.JSON,
        {Headers, [{"User-Agent", user_agent()}]}
      ],
      Mint
    )
  end

  defp caption_client(headers) do
    Tesla.client(
      [
        {Headers, headers},
        {Headers, [{"User-Agent", user_agent()}]}
      ],
      Mint
    )
  end

  defp user_agent do
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
  end
end
