defmodule AnyTalkerBot.AddTelemetryDataMiddleware do
  @moduledoc false

  use ExGram.Middleware

  @spec call(ExGram.Cnt.t(), any()) :: ExGram.Cnt.t()
  def call(context, _options) do
    add_extra(context, :received_at, :os.system_time())
  end
end
