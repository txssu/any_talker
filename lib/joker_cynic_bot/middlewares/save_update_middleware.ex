defmodule JokerCynicBot.SaveUpdateMiddleware do
  @moduledoc false
  use ExGram.Middleware

  @spec call(ExGram.Cnt.t(), any()) :: ExGram.Cnt.t()
  def call(%ExGram.Cnt{update: update} = context, _options) do
    if message = update.message do
      JokerCynic.Events.save_message(message)
    end

    with %{message: %{chat: chat}} <- update do
      if chat.type != "private" do
        user_id = update.message.from.id

        JokerCynic.Accounts.add_chat_member(user_id, chat.id, chat.title)
      end
    end

    context
  end
end
