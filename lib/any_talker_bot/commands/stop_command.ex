defmodule AnyTalkerBot.StopCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalkerBot.Reply

  @impl AnyTalkerBot.Command
  def call(%Reply{} = reply) do
    AnyTalker.NikitaPlayer.stop()
    %{reply | text: "Остановил воспроизведение"}
  end
end
