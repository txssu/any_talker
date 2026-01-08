defmodule AnyTalkerBot.IgnoreForwardedCommandsMiddleware do
  @moduledoc """
  Middleware that ignores commands from forwarded messages from users.

  Commands in forwarded messages from users
  should not be executed to prevent unauthorized command execution.
  """
  use ExGram.Middleware

  def call(%ExGram.Cnt{update: %{message: %{forward_origin: forward_origin}}} = context, _options) do
    if is_nil(forward_origin) do
      context
    else
      %{context | middleware_halted: true}
    end
  end

  def call(context, _options) do
    context
  end
end
