defmodule AnyTalker.Repo.Migrations.UpdateRateLimitFields do
  use Ecto.Migration

  def change do
    alter table(:global_config) do
      remove :ask_rate_limit, :integer
      remove :ask_rate_limit_scale_ms, :integer

      add :ask_max_tokens, :integer, null: false, default: 70000
      add :ask_refill_interval_ms, :integer, null: false, default: 1_200_000
      add :ask_refill_amount, :integer, null: false, default: 2000
    end

    alter table(:chat_configs) do
      remove :ask_rate_limit, :integer
      remove :ask_rate_limit_scale_ms, :integer

      add :ask_max_tokens, :integer
      add :ask_refill_interval_ms, :integer
      add :ask_refill_amount, :integer
    end
  end
end
