defmodule AnyTalkerBot.MoveCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.Config.GameConfig
  alias AnyTalker.Game
  alias AnyTalker.Game.Movement.MoveResult
  alias AnyTalker.Game.NewYearEvent
  alias AnyTalker.RateLimit
  alias AnyTalkerBot.Reply

  @impl AnyTalkerBot.Command
  def call(%Reply{message: {:command, :move, %{text: text}}, context: %{extra: %{user: user}}} = reply) do
    stats = Game.get_player_stats(user.id)

    if NewYearEvent.should_ignore_command?(stats.has_taken_final_step) do
      Reply.halt(reply)
    else
      handle_move(reply, user, stats, text)
    end
  end

  defp handle_move(reply, user, stats, text) do
    if NewYearEvent.event_active?() do
      handle_event_move(reply, user, stats, text)
    else
      handle_normal_move(reply, user, stats, text)
    end
  end

  defp handle_event_move(reply, user, stats, "forward") do
    handle_move_forward(reply, user, stats)
  end

  defp handle_event_move(reply, _user, _stats, _other) do
    Reply.send_message(reply, "Доступные направления: forward")
  end

  defp handle_normal_move(reply, user, stats, text) do
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
    if NewYearEvent.can_take_final_step?(stats.has_taken_final_step) do
      handle_final_step(reply, stats)
    else
      handle_normal_forward(reply, user, user_id, stats)
    end
  end

  defp handle_final_step(reply, stats) do
    Game.increment_steps(stats)
    Game.mark_final_step_taken(stats)
    Reply.send_message(reply, NewYearEvent.final_step_message())
  end

  defp handle_normal_forward(reply, user, user_id, stats) do
    rate_limit_ms = NewYearEvent.rate_limit_scale_ms() || GameConfig.rate_limit_scale_ms()
    key = "move:#{user_id}"

    with {:allow, _count} <- RateLimit.hit(key, rate_limit_ms, GameConfig.rate_limit()),
         {:ok, result} <- Game.process_forward_move(stats, user) do
      send_move_result(reply, result)
    else
      {:deny, _time_left_ms} ->
        Reply.send_message(reply, NewYearEvent.rate_limit_message())
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

  defp send_move_result(reply, %MoveResult{message_key: :move_forward, night_bonus: night_bonus}) do
    base_message =
      case NewYearEvent.current_phase() do
        :phase_1 -> NewYearEvent.phase_1_move_message()
        _other -> "Вы прошли вперёд"
      end

    message = build_message(base_message, night_bonus)
    Reply.send_message(reply, message)
  end

  defp send_move_result(reply, %MoveResult{message_key: :move_forward_with_reward, night_bonus: night_bonus}) do
    message = build_message("Вы прошли вперёд\n\nКажется, вы что-то нашли", night_bonus)
    Reply.send_message(reply, message)
  end

  defp send_move_result(reply, %MoveResult{message_key: :move_forward_with_fork, night_bonus: night_bonus}) do
    message =
      build_message("Вы прошли вперёд\n\nТропа раздваивается. Выберите направление: left или right", night_bonus)

    Reply.send_message(reply, message)
  end

  defp send_fork_prompt(reply) do
    Reply.send_message(reply, "Тропа раздваивается. Выберите направление: left или right")
  end

  defp build_message(base_message, nil), do: base_message

  defp build_message(base_message, :granted) do
    base_message <> "\n\nНочь приняла вас. На семь дней вам открыто то, что скрыто для других."
  end

  defp build_message(base_message, :denied) do
    base_message <> "\n\nТьма смотрела, но не выбрала вас."
  end
end
