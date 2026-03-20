defmodule AnyTalker.Repo.Migrations.AddGuidToRssArticles do
  use Ecto.Migration

  def change do
    alter table(:rss_articles) do
      add :guid, :string
    end

    flush()

    execute "UPDATE rss_articles SET guid = url WHERE guid IS NULL",
            "UPDATE rss_articles SET guid = NULL"

    execute "ALTER TABLE rss_articles ALTER COLUMN guid SET NOT NULL",
            "ALTER TABLE rss_articles ALTER COLUMN guid DROP NOT NULL"

    drop unique_index(:rss_articles, [:url])
    create unique_index(:rss_articles, [:feed_id, :guid])
  end
end
