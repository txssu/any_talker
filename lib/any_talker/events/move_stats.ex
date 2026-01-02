defmodule AnyTalker.Events.MoveStats do
  @moduledoc """
  Move command statistics per user.

  ## Fields

  | Field Name | Type | Description |
  |------------|------|-------------|
  | user_id | integer | User ID (primary key) |
  | forwards | integer | Number of valid forward moves |
  | left | integer | Number of valid left moves |
  | right | integer | Number of valid right moves |
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key false
  @timestamps_opts []
  schema "move_stats" do
    belongs_to :user, AnyTalker.Accounts.User, primary_key: true
    field :forwards, :integer, default: 0
    field :left, :integer, default: 0
    field :right, :integer, default: 0
  end

  @doc false
  def changeset(move_stats, attrs) do
    move_stats
    |> cast(attrs, [:user_id, :forwards, :left, :right])
    |> validate_required([:user_id])
    |> validate_number(:forwards, greater_than_or_equal_to: 0)
    |> validate_number(:left, greater_than_or_equal_to: 0)
    |> validate_number(:right, greater_than_or_equal_to: 0)
  end
end
