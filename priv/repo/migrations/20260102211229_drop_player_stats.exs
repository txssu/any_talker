defmodule AnyTalker.Repo.Migrations.DropPlayerStats do
  use Ecto.Migration

  def change do
    drop table(:player_stats)
  end
end
