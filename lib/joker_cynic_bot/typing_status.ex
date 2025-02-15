defmodule JokerCynicBot.TypingStatus do
  @moduledoc false
  use GenServer

  alias JokerCynicBot.Reply

  @spec with_typing((Reply.t() -> Reply.t()), Reply.t()) :: Reply.t()
  def with_typing(fun, reply) do
    {:ok, pid} = start_link(reply.context.update.message.chat.id)

    result = fun.(reply)

    stop(pid)

    result
  end

  @spec start_link(integer()) :: GenServer.on_start()
  def start_link(chat_id) do
    GenServer.start_link(__MODULE__, chat_id)
  end

  @spec stop(pid()) :: :ok
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
    ExGram.send_chat_action!(chat_id, "typing", bot: JokerCynicBot.Dispatcher.bot())
    Process.send_after(self(), :send_typing, 5_000)
    {:noreply, chat_id}
  end
end
