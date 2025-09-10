defmodule AnyTalker.Repo.Migrations.RemoveAllowsWriteToPmFromUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :allows_write_to_pm, :boolean, default: false, null: false
    end
  end
end
