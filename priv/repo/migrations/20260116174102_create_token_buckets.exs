defmodule AnyTalker.Repo.Migrations.CreateTokenBuckets do
  use Ecto.Migration

  def change do
    create table(:token_buckets, primary_key: false) do
      add :key, :string, primary_key: true
      add :tokens, :integer, null: false
      add :last_refill_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec)
    end
  end
end
