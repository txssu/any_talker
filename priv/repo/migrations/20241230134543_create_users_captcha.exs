defmodule JokerCynic.Repo.Migrations.CreateUsersCaptcha do
  use Ecto.Migration

  def change do
    create table(:users_captcha) do
      add :answer, :string, null: false
      add :message_ids, {:array, :bigint}, null: false
      add :chat_id, :bigint, null: false
      add :user_id, :bigint, null: false
      add :join_message_id, :bigint, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users_captcha, [:user_id, :chat_id])
  end
end
