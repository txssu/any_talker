defmodule AnyTalker.Repo.Migrations.MessageJsonToColumns do
  use Ecto.Migration

  def up do
    alter table(:messages) do
      add :sent_date, :utc_datetime
      add :from_id, :bigint
      add :text, :text
      add :source, :string
    end

    flush()

    execute("""
    UPDATE messages
    SET sent_date   = to_timestamp((content->>'date')::bigint),
        from_id     = (content->'from'->>'id')::bigint,
        text        = content->>'text',
        source      = 'telegram';
    """)

    alter table(:messages) do
      modify :sent_date, :utc_datetime, null: false
      modify :from_id, :bigint, null: false
      modify :source, :string, null: false

      modify :content, :map, null: true
    end
  end

  def down do
    alter table(:messages) do
      remove :source
      remove :text
      remove :from_id
      remove :sent_date
    end
  end
end
