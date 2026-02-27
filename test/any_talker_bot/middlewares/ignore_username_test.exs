defmodule AnyTalkerBot.Middleware.IgnoreUsernameTest do
  use AnyTalker.DataCase, async: true

  import AnyTalkerBot.BotFixtures

  alias AnyTalkerBot.Middleware.IgnoreUsername

  describe "call/2 — username stripping" do
    test "/command is passed through unchanged" do
      cnt = cnt_with_text("/privacy", username: "AnyTalkerBot")

      result = IgnoreUsername.call(cnt, [])

      assert result.update.message.text == "/privacy"
    end

    test "/command@BotUsername is transformed to /command (treated same as /command)" do
      cnt = cnt_with_text("/privacy@AnyTalkerBot", username: "AnyTalkerBot")

      result = IgnoreUsername.call(cnt, [])

      assert result.update.message.text == "/privacy"
    end

    test "/command@SomeOtherBot is left intact (not dispatched as /command)" do
      cnt = cnt_with_text("/privacy@SomeOtherBot", username: "AnyTalkerBot")

      result = IgnoreUsername.call(cnt, [])

      assert result.update.message.text == "/privacy@SomeOtherBot"
    end

    test "/command@BotUsername with arguments strips username but keeps arguments" do
      cnt = cnt_with_text("/ask@AnyTalkerBot what is Elixir?", username: "AnyTalkerBot")

      result = IgnoreUsername.call(cnt, [])

      assert result.update.message.text == "/ask what is Elixir?"
    end

    test "/command@SomeOtherBot with arguments is left fully intact" do
      cnt = cnt_with_text("/ask@SomeOtherBot what is Elixir?", username: "AnyTalkerBot")

      result = IgnoreUsername.call(cnt, [])

      assert result.update.message.text == "/ask@SomeOtherBot what is Elixir?"
    end

    test "plain text is not affected" do
      cnt = cnt_with_text("hello world", username: "AnyTalkerBot")

      result = IgnoreUsername.call(cnt, [])

      assert result.update.message.text == "hello world"
    end
  end

  defp cnt_with_text(text, username: username) do
    msg = message(%{text: text})

    [message: msg]
    |> context()
    |> Map.put(:bot_info, %ExGram.Model.User{
      id: 999,
      is_bot: true,
      first_name: "TestBot",
      username: username
    })
  end
end
