defmodule AnyTalker.NikitaPlayerTest do
  use ExUnit.Case, async: true

  alias AnyTalker.NikitaPlayer

  defp start_player do
    {:ok, pid} = GenServer.start_link(NikitaPlayer, %NikitaPlayer{state: :stop, pending_polls: [], last_command: nil})
    pid
  end

  defp setup_poll_and_timeout(pid) do
    task = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)

    Process.sleep(10)

    state = :sys.get_state(pid)
    [poll_entry] = state.pending_polls
    {caller_pid, _ref} = poll_entry.from

    {task, caller_pid}
  end

  describe "GenServer.init/1" do
    test "initializes with correct state" do
      pid = start_player()
      assert Process.alive?(pid)

      state = :sys.get_state(pid)
      assert state.state == :stop
      assert state.pending_polls == []
      assert state.last_command == nil
    end
  end

  describe "handle_cast(:play, state)" do
    test "changes state to :play" do
      pid = start_player()
      GenServer.cast(pid, :play)

      state = :sys.get_state(pid)
      assert state.state == :play
    end

    test "replies to pending polls with PLAY 1" do
      pid = start_player()

      # Start polling in separate process
      task = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)

      # Give time for poll to register
      Process.sleep(10)

      # Send play command
      GenServer.cast(pid, :play)

      # Poll should return "PLAY 1"
      result = Task.await(task)
      assert result == "PLAY 1"
    end

    test "clears pending polls after sending PLAY 1" do
      pid = start_player()

      # Start multiple polls
      task1 = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)
      task2 = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)

      Process.sleep(10)

      GenServer.cast(pid, :play)

      # Both should receive PLAY 1
      assert Task.await(task1) == "PLAY 1"
      assert Task.await(task2) == "PLAY 1"

      # Pending polls should be cleared
      state = :sys.get_state(pid)
      assert state.pending_polls == []
    end
  end

  describe "handle_cast(:stop, state)" do
    test "changes state to :stop" do
      pid = start_player()
      GenServer.cast(pid, :play)
      GenServer.cast(pid, :stop)

      state = :sys.get_state(pid)
      assert state.state == :stop
    end

    test "replies to pending polls with STOP" do
      pid = start_player()
      task = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)

      Process.sleep(10)

      GenServer.cast(pid, :stop)

      result = Task.await(task)
      assert result == "STOP"
    end

    test "clears pending polls after sending STOP" do
      pid = start_player()
      task1 = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)
      task2 = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)

      Process.sleep(10)

      GenServer.cast(pid, :stop)

      assert Task.await(task1) == "STOP"
      assert Task.await(task2) == "STOP"

      state = :sys.get_state(pid)
      assert state.pending_polls == []
    end
  end

  describe "handle_call(:poll, from, state)" do
    test "blocks when no command is pending" do
      pid = start_player()
      task = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)

      # Give some time to ensure poll is registered
      Process.sleep(10)

      # Task should still be running (blocked)
      assert Process.alive?(task.pid)

      # Send play to unblock
      GenServer.cast(pid, :play)
      assert Task.await(task) == "PLAY 1"
    end

    test "returns command immediately if one is pending" do
      pid = start_player()
      # Set last_command directly for this test
      :sys.replace_state(pid, fn state ->
        %{state | last_command: "PLAY 1"}
      end)

      result = GenServer.call(pid, :poll)
      assert result == "PLAY 1"

      # last_command should be cleared
      state = :sys.get_state(pid)
      assert state.last_command == nil
    end

    test "times out after 30 seconds" do
      pid = start_player()
      {task, caller_pid} = setup_poll_and_timeout(pid)

      send(pid, {:timeout, caller_pid})

      result = Task.await(task)
      assert result == ""
    end

    test "multiple polls can be pending simultaneously" do
      pid = start_player()
      task1 = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)
      task2 = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)
      task3 = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)

      Process.sleep(10)

      state = :sys.get_state(pid)
      assert length(state.pending_polls) == 3

      # All should receive the same command
      GenServer.cast(pid, :play)

      assert Task.await(task1) == "PLAY 1"
      assert Task.await(task2) == "PLAY 1"
      assert Task.await(task3) == "PLAY 1"
    end
  end

  describe "handle_info({:timeout, caller_pid}, state)" do
    test "removes timed out poll from pending_polls" do
      pid = start_player()
      # Start two polls
      task1 = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)
      task2 = Task.async(fn -> GenServer.call(pid, :poll, :infinity) end)

      Process.sleep(10)

      state = :sys.get_state(pid)
      assert length(state.pending_polls) == 2

      # Get the first poll's caller_pid and timeout it
      [poll_entry | _remaining_polls] = state.pending_polls
      {caller_pid, _ref} = poll_entry.from
      send(pid, {:timeout, caller_pid})

      # Wait for timeout to be processed
      Process.sleep(10)

      # One task should return empty string, the other should still be waiting
      # We can't easily test which one gets timed out, so let's just verify one returns ""
      GenServer.cast(pid, :play)
      results = [Task.await(task1), Task.await(task2)]

      # One should be "" (timed out) and one should be "PLAY 1" (from the cast)
      assert "" in results
      assert "PLAY 1" in results
    end

    test "timeout sends empty string response" do
      pid = start_player()
      {task, caller_pid} = setup_poll_and_timeout(pid)

      send(pid, {:timeout, caller_pid})

      result = Task.await(task)
      assert result == ""
    end
  end

  describe "state transitions" do
    test "maintains state correctly through play/stop cycle" do
      pid = start_player()
      initial_state = :sys.get_state(pid)
      assert initial_state.state == :stop

      GenServer.cast(pid, :play)
      play_state = :sys.get_state(pid)
      assert play_state.state == :play

      GenServer.cast(pid, :stop)
      stop_state = :sys.get_state(pid)
      assert stop_state.state == :stop
    end

    test "multiple play commands work correctly" do
      pid = start_player()
      GenServer.cast(pid, :play)
      GenServer.cast(pid, :play)

      state = :sys.get_state(pid)
      assert state.state == :play
    end

    test "multiple stop commands work correctly" do
      pid = start_player()
      GenServer.cast(pid, :play)
      GenServer.cast(pid, :stop)
      GenServer.cast(pid, :stop)

      state = :sys.get_state(pid)
      assert state.state == :stop
    end
  end
end
