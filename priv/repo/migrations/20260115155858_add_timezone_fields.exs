defmodule AnyTalker.Repo.Migrations.AddTimezoneFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :timezone, :string
    end

    alter table(:chat_configs) do
      add :timezone, :string
    end

    alter table(:global_config) do
      add :timezone, :string, default: "Europe/Moscow"
    end
  end
end
