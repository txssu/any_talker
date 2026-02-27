defmodule AnyTalkerBot.DispatcherTest do
  use AnyTalker.DataCase, async: true

  import AnyTalkerBot.BotFixtures

  alias AnyTalkerBot.Dispatcher
  alias AnyTalkerBot.Reply

  describe "build_reply/2" do
    # Regression: ExGram strips the command prefix in extract_info/1 and puts the clean
    # text in the command tuple, but the context.update.message.text still holds the
    # original "/command text". build_reply must sync the context from the tuple so that
    # Reply.message(reply).text returns only the arguments, not the full "/command text".
    test "message text contains only arguments, not the command prefix" do
      original_msg = message(%{text: "/privacy something"})
      stripped_msg = %{original_msg | text: "something"}
      command_tuple = {:command, :privacy, stripped_msg}
      ctx = context(message: original_msg)

      reply = Dispatcher.build_reply(command_tuple, ctx)

      assert Reply.message(reply).text == "something"
    end
  end

  describe "handle/2" do
    # Regression for: (KeyError) key :received_at not found in: %{}
    # lib/any_talker_bot/dispatcher.ex:36
    #
    # After refactoring, middleware moved from ExGram's pipeline into build_reply/run_middlewares.
    # ExGram now calls handle/2 with context.extra == %{}, but line 36 reads
    # context.extra.received_at. Fix: use reply.context.extra.received_at instead.
    test "does not raise KeyError when context.extra is empty (as ExGram provides it)" do
      msg = message()
      ctx = context(message: msg)

      assert ctx.extra == %{}

      # Unhandled message type → execute_command falls through to halt → Reply.execute is no-op
      result = Dispatcher.handle({:unhandled}, ctx)

      assert %ExGram.Cnt{} = result
    end
  end
end
