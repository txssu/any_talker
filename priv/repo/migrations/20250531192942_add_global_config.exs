defmodule AnyTalker.Repo.Migrations.AddGlobalConfig do
  use Ecto.Migration

  def change do
    create table(:global_config) do
      add :ask_model, :string, null: false
      add :ask_rate_limit, :integer, null: false
      add :ask_rate_limit_scale_ms, :integer, null: false
    end

    create constraint(:global_config, :singleton, check: "id = 1")

    ask_rate_limit_scale_ms = to_timeout(hour: 2)

    execute(
      "INSERT INTO global_config (ask_model, ask_rate_limit, ask_rate_limit_scale_ms) VALUES ('gpt-4o', 10, #{ask_rate_limit_scale_ms})"
    )
  end

  def down do
    drop table(:global_config)
  end
end
