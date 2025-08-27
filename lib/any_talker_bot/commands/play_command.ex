defmodule AnyTalkerBot.PlayCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalkerBot.Reply

  @impl AnyTalkerBot.Command
  def call(%Reply{} = reply) do
    AnyTalker.NikitaPlayer.play()
    %{reply | text: "Играю трек 1"}
  end
end
