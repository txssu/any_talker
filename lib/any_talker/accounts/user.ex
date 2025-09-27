defmodule AnyTalker.Accounts.User do
  @moduledoc """
  Telegram user representation.

  ## Fields

  | Field Name | Type | Description |
  |------------|------|-------------|
  | username | string | Telegram username |
  | custom_name | string | Custom display name (max 20 chars) |
  | first_name | string | Telegram first name (required) |
  | last_name | string | Telegram last name |
  | photo_url | string | Telegram profile photo URL |
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "users" do
    field :username, :string
    field :custom_name, :string
    field :first_name, :string
    field :last_name, :string
    field :photo_url, :string

    has_one :current_subscription, AnyTalker.Accounts.Subscription

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :first_name, :last_name, :photo_url, :username, :custom_name])
    |> validate_required([:first_name])
    |> validate_length(:custom_name, max: 20)
  end
end
