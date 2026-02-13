defmodule AnyTalker.Repo.Migrations.AddAskBannedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :ask_banned, :boolean, default: false, null: false
    end
  end
end
