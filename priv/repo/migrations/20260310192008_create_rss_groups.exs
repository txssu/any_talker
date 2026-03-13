defmodule AnyTalker.Repo.Migrations.CreateRssGroups do
  use Ecto.Migration

  def change do
    create table(:rss_groups) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:rss_groups, [:user_id, :name])
    create index(:rss_groups, [:user_id])
  end
end
