defmodule AnyTalker.Repo.Migrations.CreateRssFeeds do
  use Ecto.Migration

  def change do
    create table(:rss_feeds) do
      add :url, :string, null: false
      add :title, :string
      add :last_fetched_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:rss_feeds, [:url])
  end
end
