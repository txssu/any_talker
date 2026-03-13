defmodule AnyTalker.Repo.Migrations.CreateRssReadStatuses do
  use Ecto.Migration

  def change do
    create table(:rss_read_statuses) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :article_id, references(:rss_articles, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:rss_read_statuses, [:user_id, :article_id])
    create index(:rss_read_statuses, [:user_id])
  end
end
