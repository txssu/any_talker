defmodule AnyTalkerBot.AskCommandTest do
  use AnyTalker.DataCase, async: true
  use Repatch.ExUnit

  import AnyTalkerBot.BotFixtures

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.Subscription
  alias AnyTalker.AI.Generation
  alias AnyTalker.AI.Response
  alias AnyTalker.AI.Response.TextOutput
  alias AnyTalker.RateLimit.Context
  alias AnyTalker.RateLimit.TokenBucket
  alias AnyTalker.Repo
  alias AnyTalker.Settings.ChatConfig
  alias AnyTalkerBot.AskCommand
  alias AnyTalkerBot.Reply
  alias ExGram.Model.User

  describe "/ask command" do
    test "halts when user is banned" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
      {:ok, banned_user} = Accounts.ban_ask(db_user)

      msg = message(%{from: tg_user, text: "Hello?"})
      reply = build_reply(msg, banned_user, is_group: true)

      assert %Reply{halt: true} = AskCommand.call(reply, :ask)
    end

    test "sends error when used in private chat without PRO" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)

      msg = message(%{from: tg_user, text: "Hello?"})
      reply = build_reply(msg, db_user, is_group: false)

      assert %Reply{action: %Reply.Message{text: text}} = AskCommand.call(reply, :ask)
      assert String.contains?(text, "работает только в группах")
    end

    test "sends error when ask_command is disabled in chat config" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)

      msg = message(%{from: tg_user, text: "Hello?"})
      # Default ChatConfig has ask_command: false
      reply = build_reply(msg, db_user, is_group: true)

      assert %Reply{action: %Reply.Message{text: text}} = AskCommand.call(reply, :ask)
      assert String.contains?(text, "бот для тебя мёртв")
    end

    test "sends error for empty message" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
      Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro})

      # Message with no text and no photos
      msg = message(%{from: tg_user})
      reply = build_reply(msg, db_user, is_group: false)

      assert %Reply{action: %Reply.Message{text: "Не вижу вопроса!"}} = AskCommand.call(reply, :ask)
    end

    test "returns AI response for valid message in group" do
      chat_id = unique_id()
      Repo.insert!(%ChatConfig{id: chat_id, ask_command: true, promote_pro: true})

      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)

      mock_gen = build_mock_generation("Elixir is awesome!")
      Repatch.patch(AnyTalker.AI, :request, fn _envelope -> {:ok, mock_gen} end)

      msg = message(%{from: tg_user, chat: chat(%{id: chat_id, type: "group"}), text: "What is Elixir?"})
      reply = build_reply(msg, db_user, is_group: true)

      assert %Reply{action: %Reply.Message{text: text}} = AskCommand.call(reply, :ask)
      assert String.contains?(text, "Elixir is awesome!")
    end

    test "returns error message when AI request fails" do
      chat_id = unique_id()
      Repo.insert!(%ChatConfig{id: chat_id, ask_command: true, promote_pro: true})

      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)

      Repatch.patch(AnyTalker.AI, :request, fn _envelope -> {:error, :api_error} end)

      msg = message(%{from: tg_user, chat: chat(%{id: chat_id, type: "group"}), text: "What?"})
      reply = build_reply(msg, db_user, is_group: true)

      assert %Reply{action: %Reply.Message{text: "Да не"}} = AskCommand.call(reply, :ask)
    end

    test "works for PRO user in private chat" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
      Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro})

      mock_gen = build_mock_generation("PRO response!")
      Repatch.patch(AnyTalker.AI, :request, fn _envelope -> {:ok, mock_gen} end)

      msg = message(%{from: tg_user, text: "Private question"})
      reply = build_reply(msg, db_user, is_group: false)

      assert %Reply{action: %Reply.Message{text: text}} = AskCommand.call(reply, :ask)
      assert String.contains?(text, "PRO response!")
    end

    test "sends rate limit error when token bucket is exhausted" do
      chat_id = unique_id()

      Repo.insert!(%ChatConfig{
        id: chat_id,
        ask_command: true,
        promote_pro: true,
        ask_max_tokens: 10,
        ask_refill_interval_ms: 86_400_000,
        ask_refill_amount: 1
      })

      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)

      rate_context = %Context{max_tokens: 10, refill_interval_ms: 86_400_000, refill_amount: 1}
      TokenBucket.increase("ask:#{db_user.id}", 11, rate_context)

      msg = message(%{from: tg_user, chat: chat(%{id: chat_id, type: "group"}), text: "Question?"})
      reply = build_reply(msg, db_user, is_group: true)

      assert %Reply{action: %Reply.Message{text: text}} = AskCommand.call(reply, :ask)
      assert String.contains?(text, "Ты выжал лимит")
    end

    test "owner bypasses all validations and gets AI response" do
      tg_user = owner_user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Owner"}, ~w[first_name]a)

      mock_gen = build_mock_generation("Owner's answer")
      Repatch.patch(AnyTalker.AI, :request, fn _envelope -> {:ok, mock_gen} end)

      # Private chat, no PRO subscription, ask_command disabled - owner bypasses all
      msg = message(%{from: tg_user, text: "Owner question"})
      reply = build_reply(msg, db_user, is_group: false)

      assert %Reply{action: %Reply.Message{text: text}} = AskCommand.call(reply, :ask)
      assert String.contains?(text, "Owner's answer")
    end

    test "ask_detailed uses detailed response mode" do
      chat_id = unique_id()
      Repo.insert!(%ChatConfig{id: chat_id, ask_command: true, promote_pro: true})

      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)

      mock_gen = build_mock_generation("Detailed response")
      Repatch.patch(AnyTalker.AI, :request, fn _envelope -> {:ok, mock_gen} end)

      msg = message(%{from: tg_user, chat: chat(%{id: chat_id, type: "group"}), text: "Detailed?"})
      reply = build_reply(msg, db_user, is_group: true)

      assert %Reply{action: %Reply.Message{text: text}} = AskCommand.call(reply, :ask_detailed)
      assert String.contains?(text, "Detailed response")
    end
  end

  defp build_reply(msg, db_user, opts) do
    is_group = Keyword.get(opts, :is_group, true)

    [message: msg]
    |> context()
    |> Map.put(:extra, %{user: db_user, is_group: is_group})
    |> Map.put(:bot_info, %User{id: 999, is_bot: true, first_name: "TestBot"})
    |> Reply.new()
  end

  defp build_mock_generation(content) do
    %Generation{
      response: %Response{
        data: %TextOutput{content: content},
        usage: %Response.Usage{total_tokens: 10, cost: Decimal.new("0.001")}
      }
    }
  end

  defp unique_id do
    System.unique_integer([:positive, :monotonic])
  end
end
