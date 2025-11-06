defmodule AnyTalker.Repo.Migrations.AddLastForkStepToPlayerStats do
  use Ecto.Migration

  def change do
    alter table(:player_stats) do
      add :last_fork_step, :integer, default: 0, null: false
    end
  end
end
