defmodule AnyTalkerBot.SaveUpdateMiddleware do
  @moduledoc false
  use ExGram.Middleware

  def call(%ExGram.Cnt{update: %ExGram.Model.Update{update_id: id} = update} = context, _options) do
    AnyTalker.Events.save_update(id, update)

    with %{message: %{chat: chat} = message} <- update do
      AnyTalker.Events.save_new_message(message)

      if chat.type != "private" do
        user_id = update.message.from.id

        AnyTalker.Accounts.add_chat_member(user_id, chat.id, chat.title)
      end
    end

    context
  end
end
