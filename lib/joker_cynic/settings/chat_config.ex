defmodule JokerCynic.Settings.ChatConfig do
  @moduledoc false
  use Ecto.Schema

  @type t :: %__MODULE__{}

  schema "chat_configs" do
    field :title, :string
    field :antispam, :boolean, default: false

    timestamps(type: :utc_datetime)
  end
end
