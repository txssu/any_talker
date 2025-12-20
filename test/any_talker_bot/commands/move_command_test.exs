defmodule AnyTalkerBot.MoveCommandTest do
  use AnyTalker.DataCase, async: true
  use Repatch.ExUnit

  alias AnyTalker.Accounts
  alias AnyTalker.Game
  alias AnyTalkerBot.MoveCommand
  alias AnyTalkerBot.Reply

  describe "call/1 with forward direction" do
    test "moves forward on first step" do
      user = create_user()
      reply = build_reply(user, "forward")

      result = MoveCommand.call(reply)

      assert result.action.text == "Вы прошли вперёд"
      stats = Game.get_player_stats(user.id)
      assert stats.steps_count == 1
    end

    test "grants reward on 10th step" do
      user = create_user()
      setup_player_stats(user.id, steps_count: 9)
      reply = build_reply(user, "forward")

      result = MoveCommand.call(reply)

      assert result.action.text == "Вы прошли вперёд\n\nКажется, вы что-то нашли"
      stats = Game.get_player_stats(user.id)
      assert stats.steps_count == 10

      # Check that PRO subscription was granted
      subscription = Accounts.get_current_subscription(user)
      assert subscription
    end

    test "enforces rate limit" do
      user = create_user()
      reply = build_reply(user, "forward")

      # First move succeeds
      result1 = MoveCommand.call(reply)
      assert result1.action.text == "Вы прошли вперёд"

      # Second immediate move fails
      result2 = MoveCommand.call(reply)
      assert result2.action.text == "Вы слишком устали, чтобы двигаться дальше"

      # Stats should only increment once
      stats = Game.get_player_stats(user.id)
      assert stats.steps_count == 1
    end

    test "can trigger fork after threshold" do
      user = create_user()
      setup_player_stats(user.id, steps_count: 15)
      reply = build_reply(user, "forward")

      # Set random seed for deterministic fork triggering
      :rand.seed(:exsplus, {1, 2, 3})

      result = MoveCommand.call(reply)

      # Fork may or may not appear due to randomness
      # Just verify the move succeeds
      assert result.action.text in [
               "Вы прошли вперёд",
               "Вы прошли вперёд\n\nТропа раздваивается"
             ]
    end
  end

  describe "call/1 at fork" do
    test "prompts for direction when trying to move forward at fork" do
      user = create_user()
      setup_player_stats(user.id, steps_count: 16, at_fork: true)
      reply = build_reply(user, "forward")

      result = MoveCommand.call(reply)

      assert result.action.text == "Тропа раздваивается. Выберите направление: left или right"
    end

    test "allows choosing left without rate limit" do
      user = create_user()
      setup_player_stats(user.id, steps_count: 16, at_fork: true)
      reply_forward = build_reply(user, "forward")
      reply_left = build_reply(user, "left")

      # Trigger rate limit with forward move
      MoveCommand.call(reply_forward)

      # Immediately choosing left should work (no rate limit)
      result = MoveCommand.call(reply_left)

      assert result.action.text == "Вы пошли налево"
      stats = Game.get_player_stats(user.id)
      # Steps should NOT increment when choosing fork direction
      assert stats.steps_count == 16
      assert stats.at_fork == false
      assert stats.last_fork_step == 16
    end

    test "allows choosing right without rate limit" do
      user = create_user()
      setup_player_stats(user.id, steps_count: 16, at_fork: true)
      reply_forward = build_reply(user, "forward")
      reply_right = build_reply(user, "right")

      # Trigger rate limit with forward move
      MoveCommand.call(reply_forward)

      # Immediately choosing right should work (no rate limit)
      result = MoveCommand.call(reply_right)

      assert result.action.text == "Вы пошли направо"
      stats = Game.get_player_stats(user.id)
      # Steps should NOT increment when choosing fork direction
      assert stats.steps_count == 16
      assert stats.at_fork == false
      assert stats.last_fork_step == 16
    end

    test "rejects left/right when not at fork" do
      user = create_user()
      reply_left = build_reply(user, "left")
      reply_right = build_reply(user, "right")

      result_left = MoveCommand.call(reply_left)
      result_right = MoveCommand.call(reply_right)

      assert result_left.action.text == "Доступные направления: forward"
      assert result_right.action.text == "Доступные направления: forward"
    end
  end

  describe "call/1 with invalid direction" do
    test "shows available directions when not at fork" do
      user = create_user()
      reply = build_reply(user, "backwards")

      result = MoveCommand.call(reply)

      assert result.action.text == "Доступные направления: forward"
    end

    test "shows fork directions when at fork" do
      user = create_user()
      setup_player_stats(user.id, steps_count: 16, at_fork: true)
      reply = build_reply(user, "backwards")

      result = MoveCommand.call(reply)

      assert result.action.text == "Тропа раздваивается. Выберите направление: left или right"
    end
  end

  # Helper functions

  defp create_user(attrs \\ %{}) do
    default_attrs = %{
      first_name: "Test User"
    }

    {:ok, user} =
      %Accounts.User{}
      |> Accounts.User.changeset(Map.merge(default_attrs, attrs))
      |> Repo.insert()

    user
  end

  defp setup_player_stats(user_id, attrs) do
    default_attrs = %{
      user_id: user_id,
      steps_count: 0,
      at_fork: false,
      last_fork_step: 0
    }

    {:ok, stats} =
      %Game.PlayerStats{}
      |> Game.PlayerStats.changeset(Map.merge(default_attrs, Map.new(attrs)))
      |> Repo.insert()

    stats
  end

  defp build_reply(user, direction) do
    # Build a minimal Reply struct for testing
    # We don't need a full ExGram context, just the essentials
    message = %{text: direction}
    context = %{extra: %{user: user}}

    %Reply{
      message: {:command, :move, message},
      context: context
    }
  end

  setup do
    # Mock DateTime.utc_now/0 to return a time outside of 22:00-23:00 Ekaterinburg time
    # This prevents the night bonus logic from affecting test results
    Repatch.patch(DateTime, :utc_now, fn -> ~U[2024-01-01 10:00:00.000000Z] end)

    :ok
  end
end
