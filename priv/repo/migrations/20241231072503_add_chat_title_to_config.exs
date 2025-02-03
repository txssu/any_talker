defmodule JokerCynic.Repo.Migrations.AddChatTitleToConfig do
  use Ecto.Migration

  def change do
    alter table(:chat_configs) do
      add :title, :string
    end
  end
end
