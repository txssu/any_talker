defmodule AnyTalker.Repo.Migrations.AddProAskConfigToConfigs do
  use Ecto.Migration

  def change do
    alter table(:global_config) do
      add :ask_pro_rate_limit, :integer
      add :ask_pro_rate_limit_scale_ms, :integer
    end

    ask_rate_limit_scale_ms = to_timeout(minute: 40)

    execute("""
    UPDATE global_config
    SET ask_pro_rate_limit = 20,
        ask_pro_rate_limit_scale_ms = #{ask_rate_limit_scale_ms}
    WHERE id = 1
    """)

    alter table(:chat_configs) do
      add :ask_pro_rate_limit, :integer
      add :ask_pro_rate_limit_scale_ms, :integer
    end
  end
end
