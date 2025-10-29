defmodule AnyTalkerBot.MoveCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.Game
  alias AnyTalker.RateLimit
  alias AnyTalkerBot.Reply

  @rate_limit_scale_ms 3_600_000
  @rate_limit 1

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
        {:ok, _stats} = Game.increment_steps(stats)
        Reply.send_message(reply, "Вы прошли вперёд")

      {:deny, _time_left_ms} ->
        Reply.send_message(reply, "Вы слишком устали, чтобы двигаться дальше")
    end
  end
end
