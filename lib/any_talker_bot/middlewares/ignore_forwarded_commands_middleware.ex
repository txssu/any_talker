defmodule AnyTalkerBot.IgnoreForwardedCommandsMiddleware do
  @moduledoc """
  Middleware that ignores commands from forwarded messages from users.

  Commands in forwarded messages from users
  should not be executed to prevent unauthorized command execution.
  """
  use ExGram.Middleware

  def call(%ExGram.Cnt{update: %{message: %{forward_origin: nil}}} = context, _options) do
    context
  end

  def call(%ExGram.Cnt{} = context, _options) do
    %{context | middleware_halted: true}
  end
end
