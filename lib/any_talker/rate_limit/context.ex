defmodule AnyTalker.RateLimit.Context do
  @moduledoc """
  Configuration context for token bucket rate limiting.

  ## Fields

  | Field Name         | Type    | Description                                |
  |--------------------|---------|--------------------------------------------|
  | max_tokens         | integer | Maximum tokens a bucket can hold           |
  | refill_interval_ms | integer | Milliseconds between refill events         |
  | refill_amount      | integer | Number of tokens added per refill interval |
  """

  @type t :: %__MODULE__{
          max_tokens: pos_integer(),
          refill_interval_ms: pos_integer(),
          refill_amount: pos_integer()
        }

  defstruct [:max_tokens, :refill_interval_ms, :refill_amount]

  @doc """
  Creates a new Context from a map.

  ## Examples

      Context.new(%{max_tokens: 10, refill_interval_ms: 60_000, refill_amount: 1})
      #=> %Context{max_tokens: 10, refill_interval_ms: 60_000, refill_amount: 1}

  """
  def new(attrs) when is_map(attrs) do
    %__MODULE__{
      max_tokens: Map.fetch!(attrs, :max_tokens),
      refill_interval_ms: Map.fetch!(attrs, :refill_interval_ms),
      refill_amount: Map.fetch!(attrs, :refill_amount)
    }
  end
end
