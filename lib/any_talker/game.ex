defmodule AnyTalker.Game do
  @moduledoc false

  import Ecto.Query

  alias AnyTalker.Accounts.User
  alias AnyTalker.Game.Movement
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
      nil -> %PlayerStats{user_id: user_id, steps_count: 0, at_fork: false}
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

  @doc """
  Sets the at_fork flag to true for a player.

  ## Examples

      iex> set_at_fork(%PlayerStats{user_id: 123, at_fork: false})
      {:ok, %PlayerStats{at_fork: true}}

  """
  def set_at_fork(%PlayerStats{} = stats) do
    stats
    |> PlayerStats.changeset(%{at_fork: true})
    |> Repo.insert_or_update()
  end

  @doc """
  Clears the at_fork flag for a player.

  ## Examples

      iex> clear_fork(%PlayerStats{user_id: 123, at_fork: true})
      {:ok, %PlayerStats{at_fork: false}}

  """
  def clear_fork(%PlayerStats{} = stats) do
    stats
    |> PlayerStats.changeset(%{at_fork: false})
    |> Repo.insert_or_update()
  end

  @doc """
  Updates the last_fork_step to the current steps_count.

  ## Examples

      iex> update_last_fork_step(%PlayerStats{user_id: 123, steps_count: 20})
      {:ok, %PlayerStats{last_fork_step: 20}}

  """
  def update_last_fork_step(%PlayerStats{} = stats) do
    stats
    |> PlayerStats.changeset(%{last_fork_step: stats.steps_count})
    |> Repo.insert_or_update()
  end

  @doc """
  Returns top players ordered by steps count.

  ## Examples

      iex> top_players()
      [%{user: %User{}, stats: %PlayerStats{steps_count: 100}}, ...]

      iex> top_players(10)
      [%{user: %User{}, stats: %PlayerStats{steps_count: 100}}, ...]

  """
  def top_players(limit \\ 50) do
    query =
      from(ps in PlayerStats,
        join: u in User,
        on: ps.user_id == u.id,
        where: ps.steps_count > 0,
        order_by: [desc: ps.steps_count],
        limit: ^limit,
        select: %{user: u, stats: ps}
      )

    Repo.all(query)
  end

  @doc """
  Processes a forward move for a player.

  Delegates to Movement module for business logic.

  ## Examples

      iex> process_forward_move(stats, user)
      {:ok, %{message_key: :move_forward, should_trigger_fork: false, reward_granted: false}}

  """
  defdelegate process_forward_move(stats, user), to: Movement

  @doc """
  Processes a fork direction choice.

  Delegates to Movement module for business logic.

  ## Examples

      iex> process_fork_choice(stats, "left")
      {:ok, :chose_left}

  """
  defdelegate process_fork_choice(stats, direction), to: Movement
end
