defmodule AnyTalker.Repo.Migrations.AddPromoteProToChatConfigs do
  use Ecto.Migration

  def change do
    alter table(:chat_configs) do
      add :promote_pro, :boolean, default: true, null: false
    end
  end
end
