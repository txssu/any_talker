defmodule AnyTalker.Repo.Migrations.RemoveAskProRateLimitFields do
  use Ecto.Migration

  def change do
    alter table(:global_config) do
      remove :ask_pro_rate_limit, :integer
      remove :ask_pro_rate_limit_scale_ms, :integer
    end

    alter table(:chat_configs) do
      remove :ask_pro_rate_limit, :integer
      remove :ask_pro_rate_limit_scale_ms, :integer
    end
  end
end
