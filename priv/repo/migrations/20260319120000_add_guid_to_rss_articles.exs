defmodule AnyTalker.Repo.Migrations.AddGuidToRssArticles do
  use Ecto.Migration

  def change do
    alter table(:rss_articles) do
      add :guid, :string
    end

    flush()

    execute "UPDATE rss_articles SET guid = url WHERE guid IS NULL", ""

    create unique_index(:rss_articles, [:guid])
  end
end
