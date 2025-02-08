defmodule JokerCynic.ChRepo.Migrations.MoveEventsToClickhouse do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false, engine: "ReplacingMergeTree") do
      add :message_id, :Int64, primary_key: true
      add :date, :Int64
      add :text, :String
      add :from_id, :Int64
      add :from_username, :String
      add :from_first_name, :String
      add :chat_id, :Int64, primary_key: true
      add :chat_title, :String

      timestamps(type: :utc_datetime)
    end
  end
end
