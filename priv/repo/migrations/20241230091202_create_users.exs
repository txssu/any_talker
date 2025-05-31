defmodule AnyTalker.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :allows_write_to_pm, :boolean, default: false, null: false
      add :first_name, :string
      add :last_name, :string
      add :photo_url, :string
      add :username, :string

      timestamps(type: :utc_datetime)
    end
  end
end
