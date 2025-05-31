defmodule AnyTalker.Repo.Migrations.RemoveDirection do
  use Ecto.Migration

  def up do
    alter table(:messages) do
      remove :direction, :string
    end
  end
end
