defmodule AnyTalker.Repo.Migrations.CreatePlayerStats do
  use Ecto.Migration

  def change do
    create table(:player_stats, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), primary_key: true
      add :steps_count, :integer, default: 0, null: false

      timestamps(type: :utc_datetime_usec)
    end
  end
end
