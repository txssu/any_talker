defmodule AnyTalker.Repo.Migrations.AddHasTakenFinalStepToPlayerStats do
  use Ecto.Migration

  def change do
    alter table(:player_stats) do
      add :has_taken_final_step, :boolean, default: false, null: false
    end
  end
end
