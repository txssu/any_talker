# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule JokerCynicBot do
  @moduledoc """
  The entrypoint for defining Telegram bot.
  """

  def command do
    quote do
      @behaviour JokerCynicBot.Command

      import JokerCynic.LocalizationUtils
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defdelegate bot, to: JokerCynicBot.Dispatcher
end
