defmodule AnyTalker.Repo.Migrations.UpdateCaptcha do
  use Ecto.Migration

  def up do
    create table(:captchas) do
      add :answer, :string, null: false

      add :chat_id, :bigint, null: false
      add :user_id, :bigint, null: false

      add :username, :string, null: false

      add :join_message_id, :bigint, null: false
      add :captcha_message_id, :bigint, null: false
      add :status, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:captchas, [:user_id, :chat_id])

    drop table(:users_captcha)
  end

  def down do
    drop table(:captchas)

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
