defmodule AnyTalker.Repo.Migrations.CreateReminders do
  use Ecto.Migration

  def change do
    create table(:reminders) do
      add :message, :text, null: false
      add :chat_id, :bigint, null: false
      add :user_id, :bigint, null: false
      add :reply_to_id, :bigint
      add :scheduled_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:reminders, [:user_id])
    create index(:reminders, [:scheduled_at])

    # Migrate existing reminders from oban_jobs
    execute(
      """
      INSERT INTO reminders (message, chat_id, user_id, reply_to_id, scheduled_at, inserted_at, updated_at)
      SELECT
        args->>'message' as message,
        (args->>'chat_id')::bigint as chat_id,
        (args->>'user_id')::bigint as user_id,
        (args->>'reply_to_id')::bigint as reply_to_id,
        COALESCE(scheduled_at, inserted_at) as scheduled_at,
        inserted_at,
        inserted_at as updated_at
      FROM oban_jobs
      WHERE worker = 'AnyTalker.AI.SendReminderJob'
        AND args->>'message' IS NOT NULL
        AND args->>'chat_id' IS NOT NULL
        AND args->>'user_id' IS NOT NULL
      """,
      "-- No rollback for data migration"
    )
  end
end
