defmodule AnyTalkerBot.MoveCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.Accounts
  alias AnyTalker.Game
  alias AnyTalker.RateLimit
  alias AnyTalkerBot.Reply

  @rate_limit_scale_ms 3_600_000
  @rate_limit 1
  @reward_steps [10, 65]
  @reward_days 7
  @fork_trigger_steps 15
  @fork_chance 0.02
  @fork_chance_multiplier 1.2

  @move_forward "Вы прошли вперёд"
  @fork_chose_direction "Тропа раздваивается. Выберите направление: left или right"

  @impl AnyTalkerBot.Command
  def call(%Reply{message: {:command, :move, message}} = reply) do
    user = reply.context.extra.user
    stats = Game.get_player_stats(user.id)

    case message.text do
      "forward" when stats.at_fork ->
        Reply.send_message(reply, @fork_chose_direction)

      "forward" ->
        handle_move_forward(reply, user, stats)

      direction when direction in ["left", "right"] and stats.at_fork ->
        process_move(reply, user, stats, {:fork_choice, direction})

      direction when direction in ["left", "right"] ->
        Reply.send_message(reply, "Доступные направления: forward")

      _other when stats.at_fork ->
        Reply.send_message(reply, @fork_chose_direction)

      _other ->
        Reply.send_message(reply, "Доступные направления: forward")
    end
  end

  defp handle_move_forward(reply, user, stats) do
    key = "move:#{user.id}"

    with {:allow, _count} <- RateLimit.hit(key, @rate_limit_scale_ms, @rate_limit),
         {:ok, updated_stats} <- Game.increment_steps(stats) do
      process_move(reply, user, updated_stats, :forward)
    else
      {:deny, _time_left_ms} ->
        Reply.send_message(reply, "Вы слишком устали, чтобы двигаться дальше")
    end
  end

  defp process_move(reply, user, stats, :forward) do
    new_steps = stats.steps_count

    {message, should_trigger_fork} =
      cond do
        new_steps in @reward_steps ->
          grant_reward(user)
          {"#{@move_forward}\n\nКажется, вы что-то нашли", false}

        new_steps > @fork_trigger_steps ->
          effective_chance = @fork_chance * calculate_fork_chance_multiplier(stats)

          if :rand.uniform() < effective_chance do
            {"#{@move_forward}\n\n#{@fork_chose_direction}", true}
          else
            {@move_forward, false}
          end

        true ->
          {@move_forward, false}
      end

    if should_trigger_fork do
      Game.set_at_fork(stats)
    end

    Reply.send_message(reply, message)
  end

  defp process_move(reply, _user, stats, {:fork_choice, direction}) do
    Game.clear_fork(stats)
    Game.update_last_fork_step(stats)

    message =
      case direction do
        "left" -> "Вы пошли налево"
        "right" -> "Вы пошли направо"
      end

    Reply.send_message(reply, message)
  end

  defp grant_reward(user) do
    Accounts.activate_pro_subscription_for_days(user, @reward_days)
  end

  defp calculate_fork_chance_multiplier(stats) do
    attempts_after_threshold =
      max(1, stats.steps_count - max(stats.last_fork_step, @fork_trigger_steps))

    :math.pow(@fork_chance_multiplier, attempts_after_threshold - 1)
  end
end
