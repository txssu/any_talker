defmodule AnyTalker.Accounts.User do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "users" do
    field :username, :string
    field :allows_write_to_pm, :boolean, default: false
    field :custom_name, :string
    field :first_name, :string
    field :last_name, :string
    field :photo_url, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :allows_write_to_pm, :first_name, :last_name, :photo_url, :username, :custom_name])
    |> validate_required([:first_name])
    |> validate_length(:custom_name, max: 20)
  end
end
