defmodule AnyTalker.Repo.Migrations.CreateChatsMembers do
  use Ecto.Migration

  def change do
    create table(:chats_members) do
      add :chat_id, :bigint
      add :user_id, :bigint

      timestamps(type: :utc_datetime)
    end

    create unique_index(:chats_members, [:chat_id, :user_id])
  end
end
