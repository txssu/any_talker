defmodule AnyTalker.Repo.Migrations.SplitAntispamToggles do
  use Ecto.Migration

  def up do
    alter table(:chat_configs) do
      add :antispam_captcha, :boolean, default: false, null: false
      add :antispam_via, :boolean, default: false, null: false
      add :antispam_keywords_enabled, :boolean, default: false, null: false
    end

    execute "UPDATE chat_configs SET antispam_captcha = antispam, antispam_via = antispam, antispam_keywords_enabled = antispam"

    alter table(:chat_configs) do
      remove :antispam
    end
  end

  def down do
    alter table(:chat_configs) do
      add :antispam, :boolean, default: false, null: false
    end

    execute "UPDATE chat_configs SET antispam = (antispam_captcha OR antispam_via OR antispam_keywords_enabled)"

    alter table(:chat_configs) do
      remove :antispam_captcha
      remove :antispam_via
      remove :antispam_keywords_enabled
    end
  end
end
