defmodule JokerCynic.Repo.Migrations.RevertDeletingAnalyticsTables do
  use Ecto.Migration

  def change do
    create table(:updates) do
      add :value, :map

      timestamps(type: :utc_datetime)
    end

    create table(:sent_messages) do
      add :value, :map

      timestamps(type: :utc_datetime)
    end
  end
end
