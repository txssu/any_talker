defmodule AnyTalkerBot.MoveCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.Accounts
  alias AnyTalker.Game
  alias AnyTalker.RateLimit
  alias AnyTalkerBot.Reply

  @rate_limit_scale_ms 3_600_000
  @rate_limit 1
  @reward_steps 10
  @reward_days 5

  @impl AnyTalkerBot.Command
  def call(%Reply{message: {:command, :move, message}} = reply) do
    user = reply.context.extra.user

    case message.text do
      "forward" ->
        handle_move_forward(reply, user)

      _other ->
        Reply.send_message(reply, "Доступные направления: forward")
    end
  end

  defp handle_move_forward(reply, user) do
    key = "move:#{user.id}"

    case RateLimit.hit(key, @rate_limit_scale_ms, @rate_limit) do
      {:allow, _count} ->
        stats = Game.get_player_stats(user.id)
        {:ok, updated_stats} = Game.increment_steps(stats)
        new_steps = updated_stats.steps_count

        message =
          if new_steps == @reward_steps do
            grant_reward(user)
            "Вы прошли вперёд\n\nКажется, вы что-то нашли"
          else
            "Вы прошли вперёд"
          end

        Reply.send_message(reply, message)

      {:deny, _time_left_ms} ->
        Reply.send_message(reply, "Вы слишком устали, чтобы двигаться дальше")
    end
  end

  defp grant_reward(user) do
    Accounts.activate_pro_subscription_for_days(user, @reward_days)
  end
end
