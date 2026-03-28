defmodule AnyTalker.AI.Envelope.SourceTest do
  use AnyTalker.DataCase, async: true

  import AnyTalkerBot.BotFixtures

  alias AnyTalker.Accounts
  alias AnyTalker.AI.Envelope.Context
  alias AnyTalker.AI.Envelope.Source
  alias AnyTalker.Settings
  alias ExGram.Model.ChosenInlineResult

  describe "to_envelope for ChosenInlineResult" do
    test "sets source to :inline" do
      tg_user = user()
      {:ok, db_user} = Accounts.upsert_user(%{id: tg_user.id, first_name: "Test"}, ~w[first_name]a)

      result = %ChosenInlineResult{
        result_id: "ask",
        from: tg_user,
        query: "test query",
        inline_message_id: "msg_1"
      }

      config = Settings.get_full_chat_config(nil)
      context = %Context{author: db_user, chat: config}

      envelope = Source.to_envelope(result, context)

      assert envelope.source == :inline
    end
  end
end
