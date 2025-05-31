defmodule AnyTalker.AI.OpenAIClient do
  @moduledoc false
  import Pathex
  import Pathex.Lenses

  alias AnyTalker.AI.Response

  require Logger

  @spec response(keyword()) :: {:ok, Response.t()} | {:error, any()}
  def response(options) do
    body = %{
      input: Keyword.fetch!(options, :input),
      instructions: Keyword.get(options, :instructions),
      model: Keyword.fetch!(options, :model),
      previous_response_id: Keyword.get(options, :previous_response_id)
    }

    with {:ok, %{body: body}} <- Tesla.post(client(), "/v1/responses", body) do
      cast_response(body)
    end
  end

  defp cast_response(api_response) do
    with {:ok, response_id} <- cast_response_id(api_response),
         {:ok, total_tokens} <- cast_total_tokens(api_response),
         {:ok, model} <- cast_model(api_response),
         {:ok, output_text} <- cast_output_text(api_response) do
      response = %Response{id: response_id, model: model, output_text: output_text, total_tokens: total_tokens}
      {:ok, response}
    else
      :error -> {:error, api_response}
    end
  end

  defp cast_response_id(api_response), do: check_nil(api_response["id"])
  defp cast_total_tokens(api_response), do: check_nil(api_response["usage"]["total_tokens"])
  defp cast_model(api_response), do: check_nil(api_response["model"])

  defp cast_output_text(api_response) do
    output_texts =
      api_response
      |> Pathex.get(
        path("output")
        ~> star()
        ~> matching(%{"type" => "message"})
        ~> path("content")
        ~> star()
        ~> matching(%{"type" => "output_text"})
        ~> path("text")
      )
      |> List.wrap()
      |> List.flatten()

    case output_texts do
      [nil] -> :error
      texts -> {:ok, Enum.join(texts)}
    end
  end

  defp check_nil(nil), do: :error
  defp check_nil(value), do: {:ok, value}

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
