defmodule AnyTalkerBot.ProInfoCommandTest do
  use AnyTalker.DataCase, async: true

  import AnyTalkerBot.BotFixtures

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.Subscription
  alias AnyTalkerBot.Dispatcher
  alias AnyTalkerBot.Reply

  test "/que_pro sends no subscription message when user has no subscription" do
    {command, ctx} = command(:que_pro)

    reply = Dispatcher.build_reply(command, ctx)

    assert %Reply{action: %Reply.Message{text: text}} = reply
    assert String.contains?(text, "нет активной подписки")
  end

  test "/que_pro shows perpetual subscription info" do
    tg_user = user()
    {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: tg_user.first_name}, ~w[first_name]a)
    Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro})

    {command, ctx} = command(:que_pro, message(%{from: tg_user}))

    reply = Dispatcher.build_reply(command, ctx)

    assert %Reply{action: %Reply.Message{text: text}} = reply
    assert String.contains?(text, "бессрочно")
  end

  test "/que_pro shows subscription expiration date" do
    tg_user = user()
    {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: tg_user.first_name}, ~w[first_name]a)

    expires_at =
      DateTime.utc_now()
      |> DateTime.add(365, :day)
      |> DateTime.truncate(:microsecond)

    Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro, expires_at: expires_at})

    expected =
      expires_at
      |> DateTime.shift_zone!("Asia/Yekaterinburg")
      |> Calendar.strftime("%d.%m.%Y в %H:%M ЕКБ")

    {command, ctx} = command(:que_pro, message(%{from: tg_user}))

    reply = Dispatcher.build_reply(command, ctx)

    assert %Reply{action: %Reply.Message{text: text}} = reply
    assert String.contains?(text, expected)
  end
end
