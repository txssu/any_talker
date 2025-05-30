defmodule JokerCynicBot.VCommand do
  @moduledoc false
  use JokerCynicBot, :command

  alias JokerCynic.BuildInfo

  @impl JokerCynicBot.Command
  def call(reply) do
    %{reply | text: "Текущая версия бота #{BuildInfo.git_short_hash()}", for_dm: true}
  end
end
