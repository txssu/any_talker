defmodule AnyTalker.Repo.Migrations.AddExpiresAtIndexToSubscriptions do
  use Ecto.Migration

  def change do
    create index(:subscriptions, [:user_id, :expires_at])
  end
end
