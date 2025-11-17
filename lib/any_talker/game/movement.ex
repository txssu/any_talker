defmodule AnyTalker.Game.Movement do
  @moduledoc """
  Handles game movement logic including forward movement, fork events, and rewards.

  This module contains the core business logic for player movement mechanics,
  separated from the presentation layer (Telegram commands).
  """

  alias AnyTalker.Accounts
  alias AnyTalker.Config.GameConfig
  alias AnyTalker.Game
  alias AnyTalker.Game.PlayerStats

  defmodule MoveResult do
    @moduledoc """
    Result of a forward movement operation.

    ## Fields

    | Field | Type | Description |
    |-------|------|-------------|
    | message_key | atom | Type of message to display (:move_forward, :move_forward_with_reward, :move_forward_with_fork) |
    | should_trigger_fork | boolean | Whether a fork event was triggered |
    | reward_granted | boolean | Whether a reward was granted to the player |
    """

    @enforce_keys [:message_key, :should_trigger_fork, :reward_granted]
    defstruct [:message_key, :should_trigger_fork, :reward_granted]

    @type t :: %__MODULE__{
            message_key: :move_forward | :move_forward_with_reward | :move_forward_with_fork,
            should_trigger_fork: boolean(),
            reward_granted: boolean()
          }
  end

  @doc """
  Processes a forward move for a player.

  Increments the player's step count, checks for rewards and fork events,
  and returns the result of the move.

  ## Examples

      iex> process_forward_move(stats, user)
      {:ok, %MoveResult{message_key: :move_forward, should_trigger_fork: false, reward_granted: false}}

      iex> process_forward_move(stats_at_reward_step, user)
      {:ok, %MoveResult{message_key: :move_forward_with_reward, should_trigger_fork: false, reward_granted: true}}
  """
  def process_forward_move(%PlayerStats{} = stats, user) do
    with {:ok, updated_stats} <- Game.increment_steps(stats) do
      %MoveResult{should_trigger_fork: should_trigger_fork} = result = evaluate_move(updated_stats, user)

      if should_trigger_fork do
        Game.set_at_fork(updated_stats)
      end

      {:ok, result}
    end
  end

  @doc """
  Processes a fork direction choice (left or right).

  Clears the fork state and updates the last fork step for the player.

  ## Examples

      iex> process_fork_choice(stats, "left")
      {:ok, :chose_left}

      iex> process_fork_choice(stats, "right")
      {:ok, :chose_right}
  """
  def process_fork_choice(%PlayerStats{} = stats, direction) when direction in ["left", "right"] do
    Game.clear_fork(stats)
    Game.update_last_fork_step(stats)

    result =
      case direction do
        "left" -> :chose_left
        "right" -> :chose_right
      end

    {:ok, result}
  end

  defp evaluate_move(%PlayerStats{steps_count: steps_count} = stats, user) do
    reward_granted = should_grant_reward?(steps_count)
    should_trigger_fork = should_trigger_fork?(stats, steps_count)

    if reward_granted do
      grant_reward(user)
    end

    %MoveResult{
      message_key: determine_message_key(reward_granted, should_trigger_fork),
      should_trigger_fork: should_trigger_fork,
      reward_granted: reward_granted
    }
  end

  defp should_grant_reward?(steps) when is_integer(steps) do
    steps in GameConfig.reward_steps()
  end

  defp should_trigger_fork?(%PlayerStats{} = stats, new_steps) do
    if new_steps > GameConfig.fork_trigger_steps() do
      effective_chance = GameConfig.fork_chance() * calculate_fork_chance_multiplier(stats)
      :rand.uniform() < effective_chance
    else
      false
    end
  end

  defp calculate_fork_chance_multiplier(%PlayerStats{steps_count: steps_count, last_fork_step: last_fork_step}) do
    attempts_after_threshold =
      max(1, steps_count - max(last_fork_step, GameConfig.fork_trigger_steps()))

    :math.pow(GameConfig.fork_chance_multiplier(), attempts_after_threshold - 1)
  end

  defp grant_reward(user) do
    Accounts.activate_pro_subscription_for_days(user, GameConfig.reward_days())
  end

  defp determine_message_key(true = _reward_granted, _should_trigger_fork) do
    :move_forward_with_reward
  end

  defp determine_message_key(false, true = _should_trigger_fork) do
    :move_forward_with_fork
  end

  defp determine_message_key(false, false) do
    :move_forward
  end
end
