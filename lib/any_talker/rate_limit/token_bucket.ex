defmodule AnyTalker.RateLimit.TokenBucket do
  @moduledoc """
  Token bucket rate limiting with configurable storage adapters.

  Provides gradual token refill over time.
  Tokens can go negative (debt is allowed).

  ## Usage

      context = %AnyTalker.RateLimit.Context{
        max_tokens: 10,
        refill_interval_ms: 60_000,
        refill_amount: 1
      }

      if AnyTalker.RateLimit.TokenBucket.allowed?("ask:123", context) do
        # Perform action...
        AnyTalker.RateLimit.TokenBucket.increase("ask:123", tokens_used, context)
      end

  """

  alias AnyTalker.RateLimit.Adapters.PostgresAdapter
  alias AnyTalker.RateLimit.Bucket
  alias AnyTalker.RateLimit.Context

  @adapter PostgresAdapter

  @doc """
  Checks if tokens are available for the given key.

  Returns `true` if current token balance > 0, `false` otherwise.
  Does not consume tokens.

  ## Examples

      context = %AnyTalker.RateLimit.Context{max_tokens: 10, refill_interval_ms: 60_000, refill_amount: 1}
      allowed?("ask:123", context)
      #=> true

  """
  def allowed?(key, %Context{} = context) when is_binary(key) do
    case @adapter.get(key) do
      nil -> true
      bucket -> calculate_current_tokens(bucket, context) > 0
    end
  end

  @doc """
  Consumes tokens from the bucket.

  On first access, creates bucket with max_tokens then subtracts.
  Tokens can go negative (debt is allowed).

  Returns `{:ok, remaining_tokens}` on success.

  ## Examples

      context = %AnyTalker.RateLimit.Context{max_tokens: 10, refill_interval_ms: 60_000, refill_amount: 1}
      increase("ask:123", 5, context)
      #=> {:ok, 5}

  """
  def increase(key, tokens, %Context{} = context) when is_binary(key) and is_integer(tokens) and tokens > 0 do
    @adapter.transaction(fn ->
      now = DateTime.utc_now()
      bucket = @adapter.get_for_update(key)

      {current_tokens, last_refill_at} =
        case bucket do
          nil ->
            {context.max_tokens, now}

          existing ->
            {calculate_current_tokens(existing, context), now}
        end

      new_tokens = current_tokens - tokens

      {:ok, _bucket} = @adapter.upsert(key, new_tokens, last_refill_at)

      new_tokens
    end)
  end

  @doc """
  Calculates time in milliseconds until at least 1 token is available.

  Returns `0` if tokens are already available.
  Returns `nil` if bucket doesn't exist (new user).

  ## Examples

      context = %AnyTalker.RateLimit.Context{max_tokens: 10, refill_interval_ms: 60_000, refill_amount: 2}
      time_until_allowed("ask:123", context)
      #=> 120000  # 2 minutes until tokens > 0

  """
  def time_until_allowed(key, %Context{} = context) when is_binary(key) do
    case @adapter.get(key) do
      nil ->
        nil

      bucket ->
        calculate_time_until_allowed(bucket, context)
    end
  end

  defp calculate_time_until_allowed(%Bucket{} = bucket, %Context{} = context) do
    now = DateTime.utc_now()
    elapsed_ms = DateTime.diff(now, bucket.last_refill_at, :millisecond)

    # How many full intervals have passed
    full_intervals_passed = div(elapsed_ms, context.refill_interval_ms)
    tokens_after_refill = min(bucket.tokens + full_intervals_passed * context.refill_amount, context.max_tokens)

    if tokens_after_refill > 0 do
      0
    else
      # Time until next refill interval completes
      time_in_current_interval = rem(elapsed_ms, context.refill_interval_ms)
      time_until_next_refill = context.refill_interval_ms - time_in_current_interval

      # Tokens needed to get to at least 1
      tokens_needed = abs(tokens_after_refill) + 1

      # How many refills needed (including the upcoming one)
      refills_needed = ceil(tokens_needed / context.refill_amount)

      # First refill comes at time_until_next_refill, rest at full intervals
      time_until_next_refill + (refills_needed - 1) * context.refill_interval_ms
    end
  end

  defp calculate_current_tokens(%Bucket{} = bucket, %Context{} = context) do
    elapsed_ms = DateTime.diff(DateTime.utc_now(), bucket.last_refill_at, :millisecond)
    refill_intervals = div(elapsed_ms, context.refill_interval_ms)
    tokens_to_add = refill_intervals * context.refill_amount

    min(bucket.tokens + tokens_to_add, context.max_tokens)
  end
end
