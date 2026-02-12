defmodule AnyTalker.AI.OpenRouter.Endpoints.Decoder do
  @moduledoc """
  Decodes OpenRouter Model Endpoints API responses.

  ## Example

      iex> data = %{"data" => %{"id" => "openai/gpt-4", "name" => "GPT-4"}}
      iex> AnyTalker.AI.OpenRouter.Endpoints.Decoder.decode(data)
      {:ok, %AnyTalker.AI.OpenRouter.Endpoints.Model{id: "openai/gpt-4", name: "GPT-4"}}
  """

  alias AnyTalker.AI.OpenRouter.Endpoints.Endpoint
  alias AnyTalker.AI.OpenRouter.Endpoints.Model
  alias AnyTalker.AI.OpenRouter.Endpoints.Pricing

  @doc """
  Decodes a map from OpenRouter Endpoints API to Model struct.

      decode(%{"data" => %{"id" => "openai/gpt-4", ...}})
      {:ok, %Model{id: "openai/gpt-4", ...}}
  """
  def decode(%{"data" => data}) when is_map(data) do
    model = %Model{
      id: data["id"],
      name: data["name"],
      created: data["created"],
      description: data["description"],
      architecture: data["architecture"],
      endpoints: decode_endpoints(data["endpoints"])
    }

    {:ok, model}
  end

  def decode(_data), do: {:error, :invalid_response}

  defp decode_endpoints(nil), do: []

  defp decode_endpoints(endpoints) when is_list(endpoints), do: Enum.map(endpoints, &decode_endpoint/1)

  defp decode_endpoint(data) do
    %Endpoint{
      name: data["name"],
      provider_name: data["provider_name"],
      context_length: data["context_length"],
      max_completion_tokens: data["max_completion_tokens"],
      max_prompt_tokens: data["max_prompt_tokens"],
      pricing: decode_pricing(data["pricing"]),
      quantization: data["quantization"],
      supported_parameters: data["supported_parameters"] || [],
      supports_implicit_caching: data["supports_implicit_caching"],
      uptime_last_30m: data["uptime_last_30m"],
      latency_last_30m: data["latency_last_30m"],
      throughput_last_30m: data["throughput_last_30m"],
      status: data["status"]
    }
  end

  defp decode_pricing(nil), do: nil

  defp decode_pricing(data) when is_map(data) do
    attrs = Map.new(Pricing.fields(), fn field -> {field, to_decimal(data[Atom.to_string(field)])} end)
    struct(Pricing, attrs)
  end

  defp to_decimal(nil), do: nil
  defp to_decimal(value) when is_binary(value), do: Decimal.new(value)
  defp to_decimal(value) when is_integer(value), do: Decimal.new(value)
  defp to_decimal(value) when is_float(value), do: Decimal.from_float(value)
end
