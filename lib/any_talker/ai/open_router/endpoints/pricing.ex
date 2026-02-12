defmodule AnyTalker.AI.OpenRouter.Endpoints.Pricing do
  @moduledoc """
  Pricing information for an OpenRouter endpoint.

  All pricing values are Decimals representing cost per token.

  | Field Name        | Type    | Description                    |
  | ----------------- | ------- | ------------------------------ |
  | prompt            | Decimal | Cost per prompt token           |
  | completion        | Decimal | Cost per completion token       |
  | request           | Decimal | Cost per request                |
  | image             | Decimal | Cost per image                  |
  | image_token       | Decimal | Cost per image token            |
  | image_output      | Decimal | Cost per output image           |
  | audio             | Decimal | Cost per audio input            |
  | audio_output      | Decimal | Cost per audio output           |
  | input_audio_cache | Decimal | Cost per cached audio input     |
  | web_search        | Decimal | Cost per web search             |
  | internal_reasoning| Decimal | Cost per internal reasoning     |
  | input_cache_read  | Decimal | Cost per input cache read       |
  | input_cache_write | Decimal | Cost per input cache write      |
  | discount          | Decimal | Discount multiplier             |
  """

  @pricing_fields [
    :prompt,
    :completion,
    :request,
    :image,
    :image_token,
    :image_output,
    :audio,
    :audio_output,
    :input_audio_cache,
    :web_search,
    :internal_reasoning,
    :input_cache_read,
    :input_cache_write,
    :discount
  ]

  def fields, do: @pricing_fields

  defstruct @pricing_fields

  @type t :: %__MODULE__{
          prompt: Decimal.t() | nil,
          completion: Decimal.t() | nil,
          request: Decimal.t() | nil,
          image: Decimal.t() | nil,
          image_token: Decimal.t() | nil,
          image_output: Decimal.t() | nil,
          audio: Decimal.t() | nil,
          audio_output: Decimal.t() | nil,
          input_audio_cache: Decimal.t() | nil,
          web_search: Decimal.t() | nil,
          internal_reasoning: Decimal.t() | nil,
          input_cache_read: Decimal.t() | nil,
          input_cache_write: Decimal.t() | nil,
          discount: Decimal.t() | nil
        }
end
