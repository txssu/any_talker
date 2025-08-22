defmodule AnyTalker.Repo.Migrations.RemoveBotNameFromGlobalConfig do
  use Ecto.Migration

  def change do
    alter table(:global_config) do
      remove :bot_name, :string
    end
  end
end
