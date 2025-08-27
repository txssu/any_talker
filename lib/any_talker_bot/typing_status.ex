defmodule AnyTalkerBot.TypingStatus do
  @moduledoc false
  use GenServer

  alias AnyTalkerBot.Reply

  def with_typing(fun, %Reply{} = reply) do
    {:ok, pid} = start_link(reply.context.update.message.chat.id)

    result = fun.(reply)

    stop(pid)

    result
  end

  def start_link(chat_id) do
    GenServer.start_link(__MODULE__, chat_id)
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  @impl GenServer
  def init(chat_id) do
    {:ok, chat_id, {:continue, :send_initial_typing}}
  end

  @impl GenServer
  def handle_continue(:send_initial_typing, chat_id), do: handle(chat_id)

  @impl GenServer
  def handle_info(:send_typing, chat_id), do: handle(chat_id)

  defp handle(chat_id) do
    ExGram.send_chat_action!(chat_id, "typing", bot: AnyTalkerBot.bot())
    Process.send_after(self(), :send_typing, 5_000)
    {:noreply, chat_id}
  end
end
