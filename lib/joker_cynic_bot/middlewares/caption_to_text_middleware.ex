defmodule JokerCynicBot.CaptionToTextMiddleware do
  @moduledoc false
  use ExGram.Middleware

  alias ExGram.Model.Message

  @spec call(ExGram.Cnt.t(), any()) :: ExGram.Cnt.t()
  def call(%{update: %{message: %Message{caption: caption}}} = context, _options) when is_binary(caption) do
    put_in(context.update.message.text, caption)
  end

  def call(context, _options), do: context
end
