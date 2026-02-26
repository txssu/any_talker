defmodule AnyTalkerBot.BanCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.User
  alias AnyTalker.TypedStructAccess
  alias AnyTalkerBot.Reply
  alias ExGram.Model.Message

  require TypedStructAccess

  @impl AnyTalkerBot.Command
  def call(%Reply{} = reply) do
    %User{} = user = TypedStructAccess.get(reply.context.extra.user, [ExGram.Cnt, Map])

    if Accounts.owner?(user) do
      handle(reply)
    else
      Reply.halt(reply)
    end
  end

  defp handle(%Reply{} = reply) do
    target_user_id =
      TypedStructAccess.get(
        reply.context.update.message.reply_to_message.from.id,
        [ExGram.Cnt, ExGram.Model.Update, Message, Message, ExGram.Model.User]
      )

    if target_user_id do
      ban_user(reply, target_user_id)
    else
      Reply.send_message(reply, "Ответь на сообщение пользователя, которого хочешь забанить.", as_reply?: true)
    end
  end

  defp ban_user(reply, target_user_id) do
    case Accounts.get_user(target_user_id) do
      %User{} = user ->
        Accounts.ban_ask(user)
        name = Accounts.display_name(user) || "ID #{user.id}"
        Reply.send_message(reply, "#{name} забанен в /ask.", as_reply?: true)

      nil ->
        Reply.send_message(reply, "Пользователь не найден.", as_reply?: true)
    end
  end
end
