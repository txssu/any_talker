defmodule AnyTalker.Repo.Migrations.AddAtForkToPlayerStats do
  use Ecto.Migration

  def change do
    alter table(:player_stats) do
      add :at_fork, :boolean, default: false, null: false
    end
  end
end
