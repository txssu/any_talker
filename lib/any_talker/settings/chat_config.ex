defmodule AnyTalker.Settings.ChatConfig do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "chat_configs" do
    field :title, :string
    field :antispam, :boolean, default: false
    field :ask_command, :boolean, default: false
    field :ask_prompt, :string

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(chat_config, attrs) do
    chat_config
    |> cast(attrs, [:antispam, :ask_command, :ask_prompt])
    |> validate_required([:antispam, :ask_command])
  end
end
