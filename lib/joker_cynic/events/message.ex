defmodule JokerCynic.Events.Message do
  @moduledoc false
  use Ecto.Schema

  @type t() :: %__MODULE__{}

  @primary_key false
  schema "messages" do
    field :message_id, Ch, type: "Int64"
    field :date, Ch, type: "Int64"
    field :text, Ch, type: "String"
    field :from_id, Ch, type: "Int64"
    field :from_username, Ch, type: "String"
    field :from_first_name, Ch, type: "String"
    field :chat_id, Ch, type: "Int64"
    field :chat_title, Ch, type: "String"

    timestamps(type: :utc_datetime)
  end
end
