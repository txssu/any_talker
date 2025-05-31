defmodule AnyTalker.Antispam.Captcha do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @required_fields ~w[status answer chat_id user_id username join_message_id captcha_message_id]a

  schema "captchas" do
    field :status, Ecto.Enum, values: ~w[created timed_out failed resolved obsoleted]a

    field :answer, :string

    field :chat_id, :integer
    field :user_id, :integer

    field :username, :string

    field :join_message_id, :integer
    field :captcha_message_id, :integer

    timestamps(type: :utc_datetime)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(captcha, attrs) do
    captcha
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
