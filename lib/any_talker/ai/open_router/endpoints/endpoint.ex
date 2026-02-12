defmodule AnyTalker.AI.OpenRouter.Endpoints.Endpoint do
  @moduledoc """
  A single provider endpoint for an OpenRouter model.

  | Field Name                | Type    | Description                                  |
  | ------------------------- | ------- | -------------------------------------------- |
  | name                      | String  | Endpoint display name                        |
  | provider_name             | String  | Provider name (e.g. OpenAI)                  |
  | context_length            | integer | Maximum context window size                  |
  | max_completion_tokens     | integer | Maximum completion tokens                    |
  | max_prompt_tokens         | integer | Maximum prompt tokens                        |
  | pricing                   | Pricing | Pricing per token (prompt, completion, etc.) |
  | quantization              | String  | Model quantization (e.g. fp16)               |
  | supported_parameters      | List    | Supported API parameters                     |
  | supports_implicit_caching | boolean | Whether implicit caching is supported        |
  | uptime_last_30m           | float   | Uptime percentage over last 30 minutes       |
  | latency_last_30m          | map     | Latency percentiles (p50, p75, p90, p99)     |
  | throughput_last_30m       | map     | Throughput percentiles (p50, p75, p90, p99)  |
  | status                    | integer | Endpoint status code                         |
  """

  defstruct [
    :name,
    :provider_name,
    :context_length,
    :max_completion_tokens,
    :max_prompt_tokens,
    :pricing,
    :quantization,
    :supports_implicit_caching,
    :uptime_last_30m,
    :latency_last_30m,
    :throughput_last_30m,
    :status,
    supported_parameters: []
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          provider_name: String.t(),
          context_length: integer(),
          max_completion_tokens: integer(),
          max_prompt_tokens: integer(),
          pricing: AnyTalker.AI.OpenRouter.Endpoints.Pricing.t() | nil,
          quantization: String.t(),
          supported_parameters: [String.t()],
          supports_implicit_caching: boolean(),
          uptime_last_30m: float(),
          latency_last_30m: map(),
          throughput_last_30m: map(),
          status: integer()
        }
end
