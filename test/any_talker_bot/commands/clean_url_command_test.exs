defmodule AnyTalkerBot.CleanUrlCommandTest do
  use AnyTalker.DataCase, async: true

  import AnyTalkerBot.BotFixtures

  alias AnyTalkerBot.Dispatcher
  alias AnyTalkerBot.Reply

  describe "/clean with text argument" do
    test "extracts and cleans URLs from command text" do
      msg = message(%{text: "/clean check this https://www.amazon.com/dp/B01N5IB20Q?tag=foo&ref=bar please"})
      {command, ctx} = command(:clean, msg)

      reply = Dispatcher.build_reply(command, ctx)

      assert %Reply{action: %Reply.Message{text: text}} = reply
      assert text =~ "1."
      assert text =~ "https://www.amazon.com/dp/B01N5IB20Q"
      refute text =~ "tag=foo"
    end

    test "handles multiple URLs" do
      msg =
        message(%{
          text:
            "/clean https://www.amazon.com/dp/B01N5IB20Q?tag=foo https://www.google.com/search?q=elixir&utm_source=twitter"
        })

      {command, ctx} = command(:clean, msg)

      reply = Dispatcher.build_reply(command, ctx)

      assert %Reply{action: %Reply.Message{text: text}} = reply
      assert text =~ "1."
      assert text =~ "2."
    end

    test "returns message when no URLs found" do
      msg = message(%{text: "/clean just some text without links"})
      {command, ctx} = command(:clean, msg)

      reply = Dispatcher.build_reply(command, ctx)

      assert %Reply{action: %Reply.Message{text: text}} = reply
      assert text =~ "Не нашёл ссылок"
    end
  end

  describe "/clean with reply" do
    test "extracts URLs from replied message text" do
      replied_msg =
        message(%{text: "Look at https://www.amazon.com/dp/B01N5IB20Q?tag=tracker&qid=123"})

      msg = message(%{text: "/clean", reply_to_message: replied_msg})
      {command, ctx} = command(:clean, msg)

      reply = Dispatcher.build_reply(command, ctx)

      assert %Reply{action: %Reply.Message{text: text}} = reply
      assert text =~ "https://www.amazon.com/dp/B01N5IB20Q"
      refute text =~ "tag=tracker"
    end

    test "extracts URLs from replied message caption" do
      replied_msg =
        message(%{text: nil, caption: "Photo from https://www.amazon.com/dp/B01N5IB20Q?tag=foo"})

      msg = message(%{text: "/clean", reply_to_message: replied_msg})
      {command, ctx} = command(:clean, msg)

      reply = Dispatcher.build_reply(command, ctx)

      assert %Reply{action: %Reply.Message{text: text}} = reply
      assert text =~ "https://www.amazon.com/dp/B01N5IB20Q"
      refute text =~ "tag=foo"
    end
  end
end
