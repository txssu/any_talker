defmodule AnyTalker.Repo.Migrations.AddCustomNameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :custom_name, :string
    end
  end
end
