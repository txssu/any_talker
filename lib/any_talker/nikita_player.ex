defmodule AnyTalker.NikitaPlayer do
  @moduledoc """
  State management for Nikita Player.

  Manages player state and handles commands (play/stop) and long polling requests.
  """

  use GenServer

  defstruct [:state, :pending_polls, :last_command]

  # Client API

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{state: :stop, pending_polls: [], last_command: nil}, name: __MODULE__)
  end

  @spec play() :: :ok
  def play do
    GenServer.cast(__MODULE__, :play)
  end

  @spec stop() :: :ok
  def stop do
    GenServer.cast(__MODULE__, :stop)
  end

  @spec poll() :: String.t()
  def poll do
    GenServer.call(__MODULE__, :poll, :infinity)
  end

  # Server callbacks

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:poll, from, %{last_command: nil, pending_polls: polls} = state) do
    # No command pending, add to polling list
    poll_entry = %{from: from, timer: schedule_timeout(from)}
    {:noreply, %{state | pending_polls: [poll_entry | polls]}}
  end

  def handle_call(:poll, _from, %{last_command: command} = state) do
    # Command is available, return it immediately and clear
    {:reply, command, %{state | last_command: nil}}
  end

  @impl GenServer
  def handle_cast(:play, %{pending_polls: polls} = state) do
    # Send "PLAY 1" to all waiting polls
    Enum.each(polls, fn %{from: from, timer: timer} ->
      Process.cancel_timer(timer)
      GenServer.reply(from, "PLAY 1")
    end)

    {:noreply, %{state | state: :play, pending_polls: [], last_command: nil}}
  end

  def handle_cast(:stop, %{pending_polls: polls} = state) do
    # Send "STOP" to all waiting polls
    Enum.each(polls, fn %{from: from, timer: timer} ->
      Process.cancel_timer(timer)
      GenServer.reply(from, "STOP")
    end)

    {:noreply, %{state | state: :stop, pending_polls: [], last_command: nil}}
  end

  @impl GenServer
  def handle_info({:timeout, caller_pid}, %{pending_polls: polls} = state) do
    # Find and remove the timed out poll, reply with empty string
    {matching_polls, remaining_polls} = Enum.split_with(polls, fn %{from: {pid, _ref}} -> pid == caller_pid end)

    Enum.each(matching_polls, fn %{from: from} ->
      GenServer.reply(from, "")
    end)

    {:noreply, %{state | pending_polls: remaining_polls}}
  end

  defp schedule_timeout({caller_pid, _ref}) do
    Process.send_after(self(), {:timeout, caller_pid}, to_timeout(second: 30))
  end
end
