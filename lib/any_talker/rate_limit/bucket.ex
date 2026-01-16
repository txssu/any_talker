defmodule AnyTalker.RateLimit.Bucket do
  @moduledoc """
  Schema for storing token bucket state in PostgreSQL.

  ## Fields

  | Field Name     | Type             | Description                          |
  |----------------|------------------|--------------------------------------|
  | key            | string           | Unique identifier for the bucket     |
  | tokens         | integer          | Current token balance (can be < 0)   |
  | last_refill_at | utc_datetime_usec| Timestamp of last refill calculation |
  """

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:key, :string, autogenerate: false}
  schema "token_buckets" do
    field :tokens, :integer
    field :last_refill_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Creates a changeset for the bucket.

  ## Examples

      Bucket.changeset(%Bucket{}, %{key: "ask:123", tokens: 10, last_refill_at: DateTime.utc_now()})

  """
  def changeset(bucket, attrs) do
    bucket
    |> cast(attrs, [:key, :tokens, :last_refill_at])
    |> validate_required([:key, :tokens, :last_refill_at])
  end
end
