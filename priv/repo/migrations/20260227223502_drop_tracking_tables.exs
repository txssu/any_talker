defmodule AnyTalker.Repo.Migrations.DropTrackingTables do
  use Ecto.Migration

  def up do
    drop_if_exists table(:messages)
    drop_if_exists table(:updates)
    drop_if_exists table(:move_stats)
  end

  def down do
    raise "Irreversible migration — tracking tables were intentionally removed"
  end
end
