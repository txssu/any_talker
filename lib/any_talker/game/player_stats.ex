defmodule AnyTalker.Game.PlayerStats do
  @moduledoc """
  Player game statistics.

  ## Fields

  | Field Name | Type | Description |
  |------------|------|-------------|
  | user_id | integer | User ID (primary key) |
  | steps_count | integer | Number of steps taken by the player |
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:user_id, :id, autogenerate: false}
  schema "player_stats" do
    field :steps_count, :integer, default: 0

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(player_stats, attrs) do
    player_stats
    |> cast(attrs, [:user_id, :steps_count])
    |> validate_required([:user_id])
    |> validate_number(:steps_count, greater_than_or_equal_to: 0)
  end
end
