defmodule JokerCynic.Repo.Migrations.MoveMessagesFromUpdatesAndSentMessages do
  use Ecto.Migration

  @disable_migration_lock true
  @disable_ddl_transaction true

  def up do
    create_if_not_exists table(:messages, primary_key: false) do
      add :message_id, :bigint, primary_key: true
      add :chat_id, :bigint, primary_key: true

      add :content, :map, null: false
      add :direction, :string, null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create_if_not_exists index(:messages, [:chat_id, :direction], concurrently: true)

    execute """
    INSERT INTO messages (message_id, chat_id, content, direction, inserted_at)
    SELECT
      (value->'message'->>'message_id')::bigint,
      (value->'message'->'chat'->>'id')::bigint,
      value->'message',
      'received',
      inserted_at
    FROM updates
    WHERE value ? 'message'
    ON CONFLICT DO NOTHING
    """

    execute """
    INSERT INTO messages (message_id, chat_id, content, direction, inserted_at)
    SELECT
      (value->>'message_id')::bigint,
      (value->'chat'->>'id')::bigint,
      value,
      'sent',
      inserted_at
    FROM sent_messages
    WHERE value->>'message_id' IS NOT NULL
      AND value->'chat'->>'id' IS NOT NULL
    ON CONFLICT DO NOTHING
    """

    drop_if_exists table(:sent_messages)
  end

  def down do
    create_if_not_exists table(:sent_messages, primary_key: false) do
      add :value, :map, null: false
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    execute("""
    INSERT INTO sent_messages (value, inserted_at)
    SELECT content, inserted_at FROM messages WHERE direction = 'sent'
    """)

    drop_if_exists index(:messages, [:chat_id, :direction])
    drop_if_exists table(:messages)
  end
end
