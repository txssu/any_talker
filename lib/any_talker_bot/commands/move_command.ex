defmodule AnyTalkerBot.MoveCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.Config.GameConfig
  alias AnyTalker.Game
  alias AnyTalker.Game.Movement.MoveResult
  alias AnyTalker.RateLimit
  alias AnyTalkerBot.Reply

  @impl AnyTalkerBot.Command
  def call(%Reply{message: {:command, :move, %{text: text}}, context: %{extra: %{user: user}}} = reply) do
    stats = Game.get_player_stats(user.id)

    case text do
      "forward" when stats.at_fork ->
        send_fork_prompt(reply)

      "forward" ->
        handle_move_forward(reply, user, stats)

      direction when direction in ["left", "right"] and stats.at_fork ->
        handle_fork_choice(reply, stats, direction)

      direction when direction in ["left", "right"] ->
        Reply.send_message(reply, "Доступные направления: forward")

      _other when stats.at_fork ->
        send_fork_prompt(reply)

      _other ->
        Reply.send_message(reply, "Доступные направления: forward")
    end
  end

  defp handle_move_forward(reply, %{id: user_id} = user, stats) do
    key = "move:#{user_id}"

    with {:allow, _count} <-
           RateLimit.hit(key, GameConfig.rate_limit_scale_ms(), GameConfig.rate_limit()),
         {:ok, result} <- Game.process_forward_move(stats, user) do
      send_move_result(reply, result)
    else
      {:deny, _time_left_ms} ->
        Reply.send_message(reply, "Вы слишком устали, чтобы двигаться дальше")
    end
  end

  defp handle_fork_choice(reply, stats, "left") do
    {:ok, :chose_left} = Game.process_fork_choice(stats, "left")
    Reply.send_message(reply, "Вы пошли налево")
  end

  defp handle_fork_choice(reply, stats, "right") do
    {:ok, :chose_right} = Game.process_fork_choice(stats, "right")
    Reply.send_message(reply, "Вы пошли направо")
  end

  defp send_move_result(reply, %MoveResult{message_key: :move_forward}) do
    Reply.send_message(reply, "Вы прошли вперёд")
  end

  defp send_move_result(reply, %MoveResult{message_key: :move_forward_with_reward}) do
    Reply.send_message(reply, "Вы прошли вперёд\n\nКажется, вы что-то нашли")
  end

  defp send_move_result(reply, %MoveResult{message_key: :move_forward_with_fork}) do
    Reply.send_message(
      reply,
      "Вы прошли вперёд\n\nТропа раздваивается. Выберите направление: left или right"
    )
  end

  defp send_fork_prompt(reply) do
    Reply.send_message(reply, "Тропа раздваивается. Выберите направление: left или right")
  end
end
