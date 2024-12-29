defmodule JokerCynic.Repo.Migrations.CreateSentMessages do
  use Ecto.Migration

  def change do
    create table(:sent_messages) do
      add :value, :map

      timestamps(type: :utc_datetime)
    end
  end
end
