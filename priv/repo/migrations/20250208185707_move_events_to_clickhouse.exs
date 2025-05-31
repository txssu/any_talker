defmodule AnyTalker.Repo.Migrations.MoveEventsToClickhouse do
  use Ecto.Migration

  def change do
    drop table(:updates)
    drop table(:sent_messages)
  end
end
