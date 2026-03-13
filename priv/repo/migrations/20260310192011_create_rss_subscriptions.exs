defmodule AnyTalker.Repo.Migrations.CreateRssSubscriptions do
  use Ecto.Migration

  def change do
    create table(:rss_subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :feed_id, references(:rss_feeds, on_delete: :delete_all), null: false
      add :group_id, references(:rss_groups, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:rss_subscriptions, [:user_id, :feed_id, :group_id])
    create index(:rss_subscriptions, [:user_id])
    create index(:rss_subscriptions, [:feed_id])
  end
end
