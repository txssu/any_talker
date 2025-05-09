defmodule JokerCynicBot.VCommand do
  @moduledoc false
  use JokerCynicBot, :command

  alias JokerCynic.BuildInfo
  alias JokerCynicBot.Reply

  @impl JokerCynicBot.Command
  def call(reply) do
    %Reply{reply | text: "Текущая версия бота #{BuildInfo.git_short_hash()}", for_dm: true}
  end
end
