# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule AnyTalkerBot do
  @moduledoc """
  The entrypoint for defining Telegram bot.
  """

  def command do
    quote do
      @behaviour AnyTalkerBot.Command

      import AnyTalker.LocalizationUtils
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defdelegate bot, to: AnyTalkerBot.Dispatcher
end
