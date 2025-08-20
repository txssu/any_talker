defmodule AnyTalkerBot.IgnoreForwardedCommandsMiddleware do
  @moduledoc """
  Middleware that ignores commands from forwarded messages from users.

  Commands in forwarded messages from users (%ExGram.Model.MessageOriginUser{})
  should not be executed to prevent unauthorized command execution.
  """
  use ExGram.Middleware

  @spec call(ExGram.Cnt.t(), any()) :: ExGram.Cnt.t()
  def call(%ExGram.Cnt{update: %{message: %{forward_origin: %ExGram.Model.MessageOriginUser{}}}} = context, _options) do
    %{context | middleware_halted: true}
  end

  def call(context, _options) do
    context
  end
end
