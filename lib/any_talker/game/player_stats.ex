defmodule AnyTalker.Game.PlayerStats do
  @moduledoc """
  Player game statistics.

  ## Fields

  | Field Name | Type | Description |
  |------------|------|-------------|
  | user_id | integer | User ID (primary key) |
  | steps_count | integer | Number of steps taken by the player |
  | at_fork | boolean | Whether the player is currently at a path fork |
  | last_fork_step | integer | Step number when player last chose a fork direction |
  | has_taken_final_step | boolean | Whether the player has taken their final step (New Year event) |
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key {:user_id, :id, autogenerate: false}
  schema "player_stats" do
    field :steps_count, :integer, default: 0
    field :at_fork, :boolean, default: false
    field :last_fork_step, :integer, default: 0
    field :has_taken_final_step, :boolean, default: false

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(player_stats, attrs) do
    player_stats
    |> cast(attrs, [:user_id, :steps_count, :at_fork, :last_fork_step, :has_taken_final_step])
    |> validate_required([:user_id])
    |> validate_number(:steps_count, greater_than_or_equal_to: 0)
    |> validate_number(:last_fork_step, greater_than_or_equal_to: 0)
  end
end
