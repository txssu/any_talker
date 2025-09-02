defmodule JokerCynic.Repo.Migrations.AddNameToImportedData do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :name_from_import, :string
    end
  end
end
