defmodule AnyTalker.RateLimit.Adapters.PostgresAdapter do
  @moduledoc """
  PostgreSQL storage adapter for token bucket rate limiting.
  """

  @behaviour AnyTalker.RateLimit.Adapter

  import Ecto.Query

  alias AnyTalker.RateLimit.Adapter
  alias AnyTalker.RateLimit.Bucket
  alias AnyTalker.Repo

  @impl Adapter
  def get(key) do
    Repo.get(Bucket, key)
  end

  @impl Adapter
  def get_for_update(key) do
    Bucket
    |> where([b], b.key == ^key)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end

  @impl Adapter
  def upsert(key, tokens, last_refill_at) do
    now = DateTime.utc_now()

    Repo.insert(
      %Bucket{
        key: key,
        tokens: tokens,
        last_refill_at: last_refill_at,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: {:replace, [:tokens, :last_refill_at, :updated_at]},
      conflict_target: [:key]
    )
  end

  @impl Adapter
  def transaction(fun) when is_function(fun, 0) do
    Repo.transaction(fn -> fun.() end)
  end
end
