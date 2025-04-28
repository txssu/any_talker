defmodule JokerCynic.Events.Message do
  @moduledoc false
  use Ecto.Schema

  @type t() :: %__MODULE__{}

  @primary_key false

  schema "messages" do
    field :message_id, :integer, primary_key: true
    field :chat_id, :integer, primary_key: true

    field :content, :map
    field :direction, Ecto.Enum, values: ~w[received sent]a

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
