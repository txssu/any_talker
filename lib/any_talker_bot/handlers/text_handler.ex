defmodule AnyTalkerBot.Handlers.TextHandler do
  @moduledoc false

  alias AnyTalkerBot.TextProcessor

  def execute(reply, {:text, _text, _message}) do
    TextProcessor.process(reply)
  end
end
