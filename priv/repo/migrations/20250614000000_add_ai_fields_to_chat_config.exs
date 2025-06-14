defmodule AnyTalker.Repo.Migrations.AddAiFieldsToChatConfig do
  use Ecto.Migration

  def change do
    alter table(:chat_configs) do
      add :ask_model, :string
      add :ask_rate_limit, :integer
      add :ask_rate_limit_scale_ms, :integer
    end
  end
end
