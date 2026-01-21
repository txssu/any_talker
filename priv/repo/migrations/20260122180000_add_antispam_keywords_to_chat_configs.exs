defmodule AnyTalker.Repo.Migrations.AddAntispamKeywordsToChatConfigs do
  use Ecto.Migration

  def change do
    alter table(:chat_configs) do
      add :antispam_keywords, :string
    end
  end
end
