defmodule AnyTalker.Repo.Migrations.RevertAddAskIgnoreUntilToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :ask_ignore_until, :utc_datetime_usec
    end
  end
end
