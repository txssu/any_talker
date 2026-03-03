defmodule AnyTalkerBot.Handlers.InlineQueryHandlerTest do
  use AnyTalker.DataCase, async: true
  use Repatch.ExUnit

  import AnyTalkerBot.BotFixtures

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.Subscription
  alias AnyTalker.Repo
  alias AnyTalkerBot.Handlers.InlineQueryHandler
  alias AnyTalkerBot.Reply
  alias ExGram.Model.InlineQuery

  describe "execute/2 with empty query" do
    test "halts on empty string" do
      reply = Reply.new(context())
      query = inline_query("")

      assert %Reply{halt: true} = InlineQueryHandler.execute(reply, {:inline_query, query})
    end

    test "halts on whitespace-only" do
      reply = Reply.new(context())
      query = inline_query("   ")

      assert %Reply{halt: true} = InlineQueryHandler.execute(reply, {:inline_query, query})
    end
  end

  describe "execute/2 collects results from matching handlers" do
    test "plain text returns only ask result for PRO user" do
      reply = Reply.new(context())
      tg_user = pro_user()
      query = inline_query("как работает квантовый компьютер", tg_user)

      assert %Reply{action: %Reply.InlineQuery{results: results}} =
               InlineQueryHandler.execute(reply, {:inline_query, query})

      assert [%{id: "ask"}] = results
    end

    test "text with URL returns clean_url and ask results for PRO user" do
      reply = Reply.new(context())
      tg_user = pro_user()
      query = inline_query("check https://example.com?utm_source=tw", tg_user)

      assert %Reply{action: %Reply.InlineQuery{results: results}} =
               InlineQueryHandler.execute(reply, {:inline_query, query})

      ids = Enum.map(results, & &1.id)
      assert "clean_url" in ids
      assert "ask" in ids
    end

    test "currency format returns currency and ask results for PRO user" do
      Repatch.patch(AnyTalker.Currency.Client, :get_currencies, fn _from ->
        {:ok, %{"rub" => 90.0}}
      end)

      reply = Reply.new(context())
      tg_user = pro_user()
      query = inline_query("usd rub 100", tg_user)

      assert %Reply{action: %Reply.InlineQuery{results: results}} =
               InlineQueryHandler.execute(reply, {:inline_query, query})

      ids = Enum.map(results, & &1.id)
      assert "currency_conversion" in ids
      assert "ask" in ids
    end

    test "plain text returns no ask result for non-PRO user" do
      reply = Reply.new(context())
      query = inline_query("как работает квантовый компьютер")

      assert %Reply{action: %Reply.InlineQuery{results: []}} =
               InlineQueryHandler.execute(reply, {:inline_query, query})
    end

    test "all results are returned with cache_time: 0 and is_personal: true" do
      reply = Reply.new(context())
      query = inline_query("hello world")

      assert %Reply{action: %Reply.InlineQuery{cache_time: 0, is_personal: true}} =
               InlineQueryHandler.execute(reply, {:inline_query, query})
    end
  end

  defp inline_query(text, tg_user \\ user()) do
    %InlineQuery{id: "q1", from: tg_user, query: text, offset: ""}
  end

  defp pro_user do
    tg_user = user()
    {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
    Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro})
    tg_user
  end
end
