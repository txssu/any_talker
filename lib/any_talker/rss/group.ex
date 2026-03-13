defmodule AnyTalker.RSS.Group do
  @moduledoc """
  Schema for a user-created RSS group (collection of feeds).

  ## Fields

  | Field Name  | Type              | Description                         |
  |-------------|-------------------|-------------------------------------|
  | name        | string            | Group name (unique per user)        |
  | user_id     | integer           | Owner user ID                       |
  | inserted_at | utc_datetime_usec | Record creation time                |
  | updated_at  | utc_datetime_usec | Record update time                  |
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias AnyTalker.Accounts.User

  schema "rss_groups" do
    field :name, :string

    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Creates a changeset for a group.

  ## Examples

      iex> changeset(%Group{}, %{name: "Tech", user_id: 123})
      %Ecto.Changeset{valid?: true}

  """
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint(:name, name: :rss_groups_user_id_name_index)
  end
end
