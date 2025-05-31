defmodule AnyTalker.Repo.Migrations.CreateChatConfigs do
  use Ecto.Migration

  def change do
    create table(:chat_configs) do
      add :antispam, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
