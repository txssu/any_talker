defmodule AnyTalkerBot.PrivacyCommandTest do
  use AnyTalker.DataCase, async: true

  import AnyTalkerBot.BotFixtures

  alias AnyTalkerBot.Dispatcher
  alias AnyTalkerBot.Reply

  test "/privacy returns a reply with text" do
    {command, ctx} = command(:privacy)

    reply = Dispatcher.build_reply(command, ctx)

    assert %Reply{action: %Reply.Message{text: text}} = reply
    assert is_binary(text) and text != ""
  end
end
