defmodule AnyTalker.Config.GameConfig do
  @moduledoc """
  Configuration for game mechanics and movement system.

  ## Configuration Parameters

  | Parameter | Type | Description |
  |-----------|------|-------------|
  | rate_limit_scale_ms | Integer | Time window for rate limiting in milliseconds (1 hour) |
  | rate_limit | Integer | Maximum number of moves allowed within the rate limit window |
  | reward_steps | List | Steps at which rewards are granted to players |
  | reward_days | Integer | Number of days of pro subscription granted as reward |
  | fork_trigger_steps | Integer | Minimum steps before fork events can occur |
  | fork_chance | Float | Base probability of fork event occurring (2%) |
  | fork_chance_multiplier | Float | Multiplier applied to fork chance for each step without fork |
  """

  @rate_limit_scale_ms 3_600_000
  @rate_limit 1
  @reward_steps [10, 65]
  @reward_days 7
  @fork_trigger_steps 15
  @fork_chance 0.02
  @fork_chance_multiplier 1.2

  def rate_limit_scale_ms, do: @rate_limit_scale_ms
  def rate_limit, do: @rate_limit
  def reward_steps, do: @reward_steps
  def reward_days, do: @reward_days
  def fork_trigger_steps, do: @fork_trigger_steps
  def fork_chance, do: @fork_chance
  def fork_chance_multiplier, do: @fork_chance_multiplier
end
