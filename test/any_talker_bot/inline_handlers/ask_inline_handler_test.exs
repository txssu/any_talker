defmodule AnyTalkerBot.InlineHandlers.AskInlineHandlerTest do
  use AnyTalker.DataCase, async: true
  use Repatch.ExUnit

  import AnyTalkerBot.BotFixtures

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.Subscription
  alias AnyTalker.AI.Generation
  alias AnyTalker.AI.History
  alias AnyTalker.AI.Message
  alias AnyTalker.AI.Response
  alias AnyTalker.AI.Response.TextOutput
  alias AnyTalker.RateLimit.Context
  alias AnyTalker.RateLimit.TokenBucket
  alias AnyTalker.Repo
  alias AnyTalker.Settings
  alias AnyTalkerBot.InlineHandlers.AskInlineHandler
  alias AnyTalkerBot.Reply
  alias ExGram.Model.ChosenInlineResult
  alias ExGram.Model.InlineQuery
  alias ExGram.Model.User

  describe "match?/1" do
    test "matches any text" do
      assert AskInlineHandler.match?("anything")
      assert AskInlineHandler.match?("купить яндекс")
      assert AskInlineHandler.match?("https://example.com")
    end
  end

  describe "build_results/1" do
    test "returns a single InlineQueryResultArticle for PRO user" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
      Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro})

      query = %InlineQuery{id: "query123", from: tg_user, query: "купить яндекс", offset: ""}

      assert [result] = AskInlineHandler.build_results(query)

      assert result.id == "ask"
      assert result.title == "Спросить AI"
      assert result.input_message_content.message_text == "<blockquote>купить яндекс</blockquote>"
      assert result.input_message_content.parse_mode == "HTML"
      assert result.description == "купить яндекс"
    end

    test "trims whitespace from query text" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
      Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro})

      query = %InlineQuery{id: "q1", from: tg_user, query: "  hello  ", offset: ""}

      assert [result] = AskInlineHandler.build_results(query)
      assert result.input_message_content.message_text == "<blockquote>hello</blockquote>"
    end

    test "result has a ⏳ loading button" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
      Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro})

      query = %InlineQuery{id: "q1", from: tg_user, query: "test", offset: ""}

      assert [result] = AskInlineHandler.build_results(query)

      [[button]] = result.reply_markup.inline_keyboard
      assert button.text == "⏳"
      assert button.callback_data == "noop"
    end

    test "returns empty list for non-PRO user" do
      tg_user = user()
      {:ok, _db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)

      query = %InlineQuery{id: "q1", from: tg_user, query: "купить яндекс", offset: ""}

      assert [] = AskInlineHandler.build_results(query)
    end
  end

  describe "handle_chosen_inline_result/2" do
    setup do
      Repatch.patch(ExGram, :edit_message_text, fn _text, _opts -> {:ok, true} end)
      :ok
    end

    test "halts when inline_message_id is nil" do
      tg_user = user()
      result = %ChosenInlineResult{result_id: "ask", from: tg_user, query: "test", inline_message_id: nil}

      assert %Reply{halt: true} = AskInlineHandler.handle_chosen_inline_result(base_reply(), result)
      refute Repatch.called?(ExGram, :edit_message_text, 2)
    end

    test "halts silently when user is banned" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
      {:ok, _banned_user} = Accounts.ban_ask(db_user)

      result = chosen_inline_result(tg_user)

      assert %Reply{halt: true} = AskInlineHandler.handle_chosen_inline_result(base_reply(), result)
      refute Repatch.called?(ExGram, :edit_message_text, 2)
    end

    test "edits message with PRO promo when user has no subscription" do
      tg_user = user()
      {:ok, _db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)

      result = chosen_inline_result(tg_user)

      assert %Reply{halt: true} = AskInlineHandler.handle_chosen_inline_result(base_reply(), result)

      assert Repatch.called?(ExGram, :edit_message_text, 2)

      [{_mod, _fun, [text, opts], _ts}] =
        Repatch.history(module: ExGram, function: :edit_message_text, arity: 2)

      assert String.contains?(text, "PRO")
      assert Keyword.get(opts, :inline_message_id) == "inline_msg_id_1"
    end

    test "edits message with rate limit notice when bucket is exhausted" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
      Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro})

      config = Settings.get_full_chat_config(nil)

      rate_context = %Context{
        max_tokens: config.ask_max_tokens,
        refill_interval_ms: config.ask_refill_interval_ms,
        refill_amount: config.ask_refill_amount
      }

      TokenBucket.increase("ask:#{db_user.id}", config.ask_max_tokens + 1, rate_context)

      result = chosen_inline_result(tg_user)

      assert %Reply{halt: true} = AskInlineHandler.handle_chosen_inline_result(base_reply(), result)

      assert Repatch.called?(ExGram, :edit_message_text, 2)

      [{_mod, _fun, [text, _opts], _ts}] =
        Repatch.history(module: ExGram, function: :edit_message_text, arity: 2)

      assert String.contains?(text, "лимит")
    end

    test "edits message with AI response on success" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
      Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro})

      mock_gen = build_mock_generation("Ответ от AI")
      Repatch.patch(AnyTalker.AI, :request, fn _envelope -> {:ok, mock_gen} end)

      result = chosen_inline_result(tg_user)

      assert %Reply{halt: true} = AskInlineHandler.handle_chosen_inline_result(base_reply(), result)

      assert Repatch.called?(ExGram, :edit_message_text, 2)

      [{_mod, _fun, [text, opts], _ts}] =
        Repatch.history(module: ExGram, function: :edit_message_text, arity: 2)

      assert String.contains?(text, "<blockquote>купить яндекс</blockquote>")
      assert String.contains?(text, "Ответ от AI")
      assert Keyword.get(opts, :inline_message_id) == "inline_msg_id_1"
    end

    test "saves conversation history after successful AI response" do
      alias AnyTalker.AI.History.Key

      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
      Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro})

      mock_gen = build_mock_generation_with_history("Ответ от AI")
      Repatch.patch(AnyTalker.AI, :request, fn _envelope -> {:ok, mock_gen} end)

      result = chosen_inline_result(tg_user)
      AskInlineHandler.handle_chosen_inline_result(base_reply(), result)

      history_key = Key.new(db_user.id, nil)
      history = History.get(history_key)
      messages = History.messages(history)

      assert length(messages) == 2

      assert hd(messages).role == "user"
      assert List.last(messages).role == "assistant"
    end

    test "AI receives previous inline history in subsequent requests" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
      Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro})

      captured_messages = :ets.new(:captured_messages, [:set, :public])

      Repatch.patch(AnyTalker.AI, :request, fn envelope ->
        # Replicate what real AI.request does: fetch history, build messages, generate
        history_key = History.Storable.to_key(envelope)
        history = History.get(history_key)

        messages =
          history
          |> History.append(AnyTalker.AI.Envelope.messages(envelope))
          |> History.messages()

        :ets.insert(captured_messages, {:messages, messages})

        # Build assistant response message the same way do_generate does
        assistant_msg = AnyTalker.AI.ToMessage.to_message(%TextOutput{content: "Два"})

        gen_history =
          messages
          |> History.new()
          |> History.append(assistant_msg)

        gen = %Generation{
          response: %Response{
            data: %TextOutput{content: "Два"},
            usage: %Response.Usage{total_tokens: 10, cost: Decimal.new("0.001")}
          },
          history: gen_history
        }

        {:ok, gen}
      end)

      # First request
      result1 = chosen_inline_result(tg_user, query: "Сколько 1+1?")
      AskInlineHandler.handle_chosen_inline_result(base_reply(), result1)

      # Second request — should see first query + response in history
      result2 = chosen_inline_result(tg_user, query: "Ты уверен?")
      AskInlineHandler.handle_chosen_inline_result(base_reply(), result2)

      [{:messages, messages}] = :ets.lookup(captured_messages, :messages)
      :ets.delete(captured_messages)

      # Should have: previous user msg, previous assistant msg, current user msg
      assert length(messages) == 3
      assert Enum.at(messages, 0).role == "user"
      assert Enum.at(messages, 1).role == "assistant"
      assert Enum.at(messages, 2).role == "user"
    end

    test "edits message with error text when AI request fails" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)
      Repo.insert!(%Subscription{user_id: db_user.id, plan: :pro})

      Repatch.patch(AnyTalker.AI, :request, fn _envelope -> {:error, :api_error} end)

      result = chosen_inline_result(tg_user)

      assert %Reply{halt: true} = AskInlineHandler.handle_chosen_inline_result(base_reply(), result)

      assert Repatch.called?(ExGram, :edit_message_text, 2)

      [{_mod, _fun, [_text, opts], _ts}] =
        Repatch.history(module: ExGram, function: :edit_message_text, arity: 2)

      assert Keyword.get(opts, :inline_message_id) == "inline_msg_id_1"
    end
  end

  defp build_mock_generation(content) do
    %Generation{
      response: %Response{
        data: %TextOutput{content: content},
        usage: %Response.Usage{total_tokens: 10, cost: Decimal.new("0.001")}
      }
    }
  end

  defp build_mock_generation_with_history(content) do
    user_msg = Message.new(nil, "user", "купить яндекс", nil)
    assistant_msg = Message.new(nil, "assistant", content, nil)

    history =
      History.new()
      |> History.append(user_msg)
      |> History.append(assistant_msg)

    %Generation{
      response: %Response{
        data: %TextOutput{content: content},
        usage: %Response.Usage{total_tokens: 10, cost: Decimal.new("0.001")}
      },
      history: history
    }
  end

  defp base_reply do
    context()
    |> Map.put(:bot_info, %User{id: 999, is_bot: true, first_name: "TestBot"})
    |> Reply.new()
  end

  defp chosen_inline_result(tg_user, opts \\ []) do
    %ChosenInlineResult{
      result_id: "ask",
      from: tg_user,
      query: Keyword.get(opts, :query, "купить яндекс"),
      inline_message_id: Keyword.get(opts, :inline_message_id, "inline_msg_id_1")
    }
  end
end
