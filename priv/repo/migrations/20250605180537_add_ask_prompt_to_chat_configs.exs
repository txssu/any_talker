defmodule AnyTalker.Repo.Migrations.AddAskPromptToChatConfigs do
  use Ecto.Migration

  def change do
    alter table(:chat_configs) do
      add :ask_prompt, :text
    end
  end
end
