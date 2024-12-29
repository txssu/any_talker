defmodule JokerCynicBot.AddTelemetryDataMiddleware do
  @moduledoc false

  use ExGram.Middleware

  def call(context, _options) do
    add_extra(context, :received_at, :os.system_time())
  end
end
