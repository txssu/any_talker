defmodule JokerCynicBot.SaveUpdateMiddleware do
  @moduledoc false
  use ExGram.Middleware

  @spec call(ExGram.Cnt.t(), any()) :: ExGram.Cnt.t()
  def call(%ExGram.Cnt{update: %ExGram.Model.Update{update_id: id} = update} = context, _options) do
    JokerCynic.Events.save_update(id, update)

    context
  end
end
