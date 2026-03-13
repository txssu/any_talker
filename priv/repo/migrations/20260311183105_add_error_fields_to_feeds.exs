defmodule AnyTalker.Repo.Migrations.AddErrorFieldsToFeeds do
  use Ecto.Migration

  def change do
    alter table(:rss_feeds) do
      add :last_error, :string
      add :last_error_at, :utc_datetime_usec
    end
  end
end
