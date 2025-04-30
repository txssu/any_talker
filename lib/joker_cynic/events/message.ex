defmodule JokerCynic.Events.Message do
  @moduledoc false
  use Ecto.Schema

  @type t() :: %__MODULE__{}

  @primary_key false

  schema "messages" do
    field :message_id, :integer, primary_key: true
    field :chat_id, :integer, primary_key: true

    field :sent_date, :utc_datetime
    field :from_id, :integer
    field :text, :string
    field :source, Ecto.Enum, values: ~w[telegram]a

    field :content, :map

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
