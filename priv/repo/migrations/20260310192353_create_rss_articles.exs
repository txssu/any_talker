defmodule AnyTalker.Repo.Migrations.CreateRssArticles do
  use Ecto.Migration

  def change do
    create table(:rss_articles) do
      add :feed_id, references(:rss_feeds, on_delete: :delete_all), null: false
      add :url, :string, null: false
      add :title, :string
      add :content, :text
      add :published_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:rss_articles, [:url])
    create index(:rss_articles, [:feed_id])
    create index(:rss_articles, [:inserted_at])
  end
end
