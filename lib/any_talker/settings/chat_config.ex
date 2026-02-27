defmodule AnyTalker.Settings.ChatConfig do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "chat_configs" do
    field :title, :string
    field :antispam_captcha, :boolean, default: false
    field :antispam_via, :boolean, default: false
    field :antispam_keywords_enabled, :boolean, default: false
    field :ask_command, :boolean, default: false
    field :ask_prompt, :string
    field :ask_model, :string
    field :ask_max_tokens, :integer
    field :ask_refill_interval_ms, :integer
    field :ask_refill_amount, :integer
    field :bot_name, :string
    field :avatar_blob, :binary
    field :avatar_updated_at, :utc_datetime
    field :promote_pro, :boolean, default: true
    field :timezone, :string
    field :antispam_keywords, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(chat_config, attrs) do
    chat_config
    |> cast(attrs, [
      :antispam_captcha,
      :antispam_via,
      :antispam_keywords_enabled,
      :antispam_keywords,
      :ask_command,
      :ask_prompt,
      :ask_model,
      :ask_max_tokens,
      :ask_refill_interval_ms,
      :ask_refill_amount,
      :bot_name,
      :promote_pro,
      :timezone
    ])
    |> validate_required([:ask_command, :promote_pro])
  end
end
