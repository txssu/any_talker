defmodule AnyTalker.Repo.Migrations.AddAskIgnoreUntilToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :ask_ignore_until, :utc_datetime_usec
    end
  end
end
