defmodule JokerCynic.AI.OpenAIClient do
  @moduledoc false
  import Pathex
  import Pathex.Lenses

  alias JokerCynic.AI.Response

  require Logger

  @spec response(keyword()) :: {:ok, Response.t()} | {:error, any()}
  def response(options) do
    body = %{
      input: Keyword.fetch!(options, :input),
      instructions: Keyword.get(options, :instructions),
      model: Keyword.get(options, :model, "gpt-4o-mini"),
      previous_response_id: Keyword.get(options, :previous_response_id)
    }

    with {:ok, %{body: body}} <- Tesla.post(client(), "/v1/responses", body) do
      {:ok, cast_response(body)}
    end
  end

  defp cast_response(api_response) do
    %Response{}
    |> cast_response_id(api_response)
    |> cast_total_tokens(api_response)
    |> cast_model(api_response)
    |> cast_output_text(api_response)
  end

  defp cast_response_id(response, api_response), do: %{response | id: api_response["id"]}
  defp cast_total_tokens(response, api_response), do: %{response | total_tokens: api_response["usage"]["total_tokens"]}
  defp cast_model(response, api_response), do: %{response | model: api_response["model"]}

  defp cast_output_text(response, api_response) do
    output_texts =
      Pathex.get(
        api_response,
        path("output")
        ~> star()
        ~> matching(%{"type" => "message"})
        ~> path("content")
        ~> star()
        ~> matching(%{"type" => "output_text"})
        ~> path("text")
      )

    output_text =
      case output_texts do
        nil ->
          nil

        list ->
          list
          |> List.flatten()
          |> Enum.join()
      end

    %{response | output_text: output_text}
  end

  defp api_url do
    fetch_env(:api_url)
  end

  defp api_key do
    token = fetch_env(:api_key)

    "Bearer #{token}"
  end

  defp client do
    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, api_url()},
        {Tesla.Middleware.Headers, [{"authorization", api_key()}]},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Timeout, timeout: 30_000}
      ],
      {Tesla.Adapter.Mint, proxy: fetch_env(:proxy_url), timeout: 30_000}
    )
  end

  defp fetch_env(key) do
    :joker_cynic
    |> Application.get_env(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
