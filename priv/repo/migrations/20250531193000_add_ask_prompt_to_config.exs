defmodule AnyTalker.Repo.Migrations.AddAskPromptToConfig do
  use Ecto.Migration

  def change do
    alter table(:chat_configs) do
      add :ask_prompt, :text
    end

    alter table(:global_config) do
      add :ask_prompt, :text
    end
  end
end
