defmodule JokerCynic.Repo.Migrations.AddAskCommandToChatConfig do
  use Ecto.Migration

  def change do
    alter table(:chat_configs) do
      add :ask_command, :boolean, default: false, null: false
    end
  end
end
