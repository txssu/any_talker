defmodule AnyTalkerBot.CaptionToTextMiddleware do
  @moduledoc false
  use ExGram.Middleware

  alias ExGram.Model.Message

  def call(%{update: %{message: %Message{caption: caption}}} = context, _options) when is_binary(caption) do
    put_in(context.update.message.text, caption)
  end

  def call(context, _options), do: context
end
