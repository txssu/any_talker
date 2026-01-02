defmodule AnyTalker.Repo.Migrations.CreateMoveStats do
  use Ecto.Migration

  def change do
    create table(:move_stats, primary_key: false) do
      add :user_id, references(:users), primary_key: true
      add :forwards, :integer, null: false, default: 0
      add :left, :integer, null: false, default: 0
      add :right, :integer, null: false, default: 0
    end
  end
end
