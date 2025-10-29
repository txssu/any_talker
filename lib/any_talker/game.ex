defmodule AnyTalker.Game do
  @moduledoc false

  alias AnyTalker.Game.PlayerStats
  alias AnyTalker.Repo

  @doc """
  Gets player statistics by user ID.

  If stats don't exist, returns a new struct with default values without inserting to DB.

  ## Examples

      iex> get_player_stats(123)
      %PlayerStats{user_id: 123, steps_count: 0}

  """
  def get_player_stats(user_id) do
    case Repo.get(PlayerStats, user_id) do
      nil -> %PlayerStats{user_id: user_id, steps_count: 0}
      stats -> stats
    end
  end

  @doc """
  Increments the steps count for a player by 1.

  ## Examples

      iex> increment_steps(%PlayerStats{user_id: 123, steps_count: 0})
      {:ok, %PlayerStats{steps_count: 1}}

  """
  def increment_steps(%PlayerStats{} = stats) do
    stats
    |> PlayerStats.changeset(%{steps_count: stats.steps_count + 1})
    |> Repo.insert_or_update()
  end
end
