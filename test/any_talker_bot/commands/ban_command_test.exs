defmodule AnyTalkerBot.BanCommandTest do
  use AnyTalker.DataCase, async: true

  import AnyTalkerBot.BotFixtures

  alias AnyTalker.Accounts
  alias AnyTalkerBot.Dispatcher
  alias AnyTalkerBot.Reply

  test "/ban halts when user is not the owner" do
    non_owner_msg = message(%{from: user()})
    {command, ctx} = command(:ban, non_owner_msg)

    reply = Dispatcher.build_reply(command, ctx)

    assert %Reply{halt: true} = reply
  end

  test "/ban asks to reply to a message when there is no reply_to_message" do
    owner_msg = message(%{from: owner_user()})
    {command, ctx} = command(:ban, owner_msg)

    reply = Dispatcher.build_reply(command, ctx)

    assert %Reply{action: %Reply.Message{text: text}} = reply
    assert String.contains?(text, "Ответь на сообщение")
  end

  test "/ban sends error when target user is not found in DB" do
    owner_msg =
      message(%{
        from: owner_user(),
        reply_to_message: message(%{from: user()})
      })

    {command, ctx} = command(:ban, owner_msg)

    reply = Dispatcher.build_reply(command, ctx)

    assert %Reply{action: %Reply.Message{text: "Пользователь не найден."}} = reply
  end

  test "/ban bans target user and sends confirmation" do
    tg_target = user()
    {:ok, target_user} = Accounts.upsert_user(%{id: tg_target.id, first_name: tg_target.first_name}, ~w[first_name]a)

    owner_msg =
      message(%{
        from: owner_user(),
        reply_to_message: message(%{from: tg_target})
      })

    {command, ctx} = command(:ban, owner_msg)

    reply = Dispatcher.build_reply(command, ctx)

    assert %Reply{action: %Reply.Message{text: text}} = reply
    assert String.contains?(text, "забанен в /ask")
    assert Accounts.get_user(target_user.id).ask_banned == true
  end
end
