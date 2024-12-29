defmodule JokerCynic.Events.SentMessage do
  @moduledoc false
  use Ecto.Schema

  schema "sent_messages" do
    field :value, :map

    timestamps(type: :utc_datetime)
  end
end
