defmodule AnyTalkerBot.BanCommandTest do
  use AnyTalker.DataCase, async: true

  import AnyTalkerBot.BotFixtures

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.User
  alias AnyTalker.Repo
  alias AnyTalkerBot.Dispatcher
  alias AnyTalkerBot.Reply

  defp insert_admin_user(tg_user) do
    Repo.insert!(%User{id: tg_user.id, first_name: tg_user.first_name, admin: true})
  end

  test "/ban halts when user is not admin" do
    non_admin_msg = message(%{from: user()})
    {command, ctx} = command(:ban, non_admin_msg)

    reply = Dispatcher.build_reply(command, ctx)

    assert %Reply{halt: true} = reply
  end

  test "/ban asks to reply to a message when there is no reply_to_message" do
    tg_admin = user()
    insert_admin_user(tg_admin)
    admin_msg = message(%{from: tg_admin})
    {command, ctx} = command(:ban, admin_msg)

    reply = Dispatcher.build_reply(command, ctx)

    assert %Reply{action: %Reply.Message{text: text}} = reply
    assert String.contains?(text, "Ответь на сообщение")
  end

  test "/ban sends error when target user is not found in DB" do
    tg_admin = user()
    insert_admin_user(tg_admin)

    admin_msg =
      message(%{
        from: tg_admin,
        reply_to_message: message(%{from: user()})
      })

    {command, ctx} = command(:ban, admin_msg)

    reply = Dispatcher.build_reply(command, ctx)

    assert %Reply{action: %Reply.Message{text: "Пользователь не найден."}} = reply
  end

  test "/ban bans target user and sends confirmation" do
    tg_admin = user()
    insert_admin_user(tg_admin)

    tg_target = user()
    {:ok, target_user} = Accounts.upsert_user(%{id: tg_target.id, first_name: tg_target.first_name}, ~w[first_name]a)

    admin_msg =
      message(%{
        from: tg_admin,
        reply_to_message: message(%{from: tg_target})
      })

    {command, ctx} = command(:ban, admin_msg)

    reply = Dispatcher.build_reply(command, ctx)

    assert %Reply{action: %Reply.Message{text: text}} = reply
    assert String.contains?(text, "забанен в /ask")
    assert Accounts.get_user(target_user.id).ask_banned == true
  end
end
