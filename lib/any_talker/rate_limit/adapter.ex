defmodule AnyTalker.RateLimit.Adapter do
  @moduledoc """
  Behaviour for token bucket storage adapters.
  """

  alias AnyTalker.RateLimit.Bucket

  @doc """
  Retrieves a bucket by key.

  Returns `nil` if not found.
  """
  @callback get(key :: String.t()) :: Bucket.t() | nil

  @doc """
  Retrieves a bucket by key with row-level lock for atomic updates.

  Returns `nil` if not found.
  """
  @callback get_for_update(key :: String.t()) :: Bucket.t() | nil

  @doc """
  Creates or updates a bucket.

  Returns `{:ok, bucket}` on success.
  """
  @callback upsert(key :: String.t(), tokens :: integer(), last_refill_at :: DateTime.t()) ::
              {:ok, Bucket.t()} | {:error, term()}

  @doc """
  Wraps operations in a transaction.

  The function receives no arguments and should return the transaction result.
  """
  @callback transaction(fun :: (-> result)) :: {:ok, result} | {:error, term()} when result: var
end
