defmodule AnyTalker.AI.OpenAIClient do
  @moduledoc false

  alias AnyTalker.AI.Response

  require Logger

  def response(options) do
    body = %{
      input: Keyword.fetch!(options, :input),
      instructions: Keyword.get(options, :instructions),
      model: Keyword.fetch!(options, :model),
      previous_response_id: Keyword.get(options, :previous_response_id),
      tools: Keyword.get(options, :tools, [])
    }

    with {:ok, %{body: resp_body}} <- Tesla.post(client(), "/v1/responses", body) do
      Response.parse(resp_body)
    end
  end

  defp api_url do
    fetch_env(:api_url)
  end

  defp api_key do
    token = fetch_env(:api_key)

    "Bearer #{token}"
  end

  defp proxy_uri do
    fetch_env(:proxy_uri)
  end

  defp client do
    proxy_opts = if(uri = proxy_uri(), do: {:proxy, uri})

    adapter_opts = Enum.reject([{:recv_timeout, 30_000}, proxy_opts], &is_nil/1)

    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, api_url()},
        {Tesla.Middleware.Headers, [{"authorization", api_key()}]},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Timeout, timeout: 30_000}
      ],
      {Tesla.Adapter.Hackney, adapter_opts}
    )
  end

  defp fetch_env(key) do
    :any_talker
    |> Application.get_env(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
