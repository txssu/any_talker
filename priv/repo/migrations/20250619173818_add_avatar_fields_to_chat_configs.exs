defmodule AnyTalker.Repo.Migrations.AddAvatarFieldsToChatConfigs do
  use Ecto.Migration

  def change do
    alter table(:chat_configs) do
      add :avatar_blob, :binary
      add :avatar_updated_at, :utc_datetime
    end
  end
end
