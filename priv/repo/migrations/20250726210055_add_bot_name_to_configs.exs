defmodule AnyTalker.Repo.Migrations.AddBotNameToConfigs do
  use Ecto.Migration

  def change do
    alter table(:global_config) do
      add :bot_name, :string
    end

    alter table(:chat_configs) do
      add :bot_name, :string
    end
  end
end
