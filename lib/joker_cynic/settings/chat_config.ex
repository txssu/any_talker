defmodule JokerCynic.Settings.ChatConfig do
  @moduledoc false
  use Ecto.Schema

  schema "chat_configs" do
    field :antispam, :boolean, default: false

    timestamps(type: :utc_datetime)
  end
end
