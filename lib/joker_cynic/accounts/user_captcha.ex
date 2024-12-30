defmodule JokerCynic.Accounts.UserCaptcha do
  @moduledoc false
  use Ecto.Schema

  @type t :: %__MODULE__{}

  schema "users_captcha" do
    field :answer, :string
    field :message_ids, {:array, :integer}
    field :chat_id, :integer
    field :user_id, :integer
    field :join_message_id, :integer

    timestamps(type: :utc_datetime)
  end
end
