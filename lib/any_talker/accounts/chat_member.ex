defmodule AnyTalker.Accounts.ChatMember do
  @moduledoc false
  use Ecto.Schema

  @type t :: %__MODULE__{}

  schema "chats_members" do
    field :chat_id, :integer
    field :user_id, :integer

    timestamps(type: :utc_datetime)
  end
end
