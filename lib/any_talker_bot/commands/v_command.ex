defmodule AnyTalkerBot.VCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.BuildInfo

  @impl AnyTalkerBot.Command
  def call(reply) do
    %{reply | text: "Текущая версия бота #{BuildInfo.git_short_hash()}", for_dm: true}
  end
end
