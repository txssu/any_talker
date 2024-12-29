defmodule JokerCynic.Repo.Migrations.CreateUpdates do
  use Ecto.Migration

  def change do
    create table(:updates) do
      add :value, :map

      timestamps(type: :utc_datetime)
    end
  end
end
