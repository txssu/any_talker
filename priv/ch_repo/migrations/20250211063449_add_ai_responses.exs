defmodule JokerCynic.ChRepo.Migrations.AddAiResponses do
  use Ecto.Migration

  def change do
    create table(:ai_responses, primary_key: false, engine: "MergeTree") do
      add :user_id, :Int64, primary_key: true
      add :chat_id, :Int64, primary_key: true
      add :message_id, :Int64, primary_key: true
      add :text, :String
      add :token_usage, :Int64
      add :model, :String

      timestamps(type: :utc_datetime)
    end
  end
end
