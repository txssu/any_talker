defmodule AnyTalkerBot.DispatcherTest do
  use AnyTalker.DataCase, async: true

  import AnyTalkerBot.BotFixtures

  alias AnyTalkerBot.Dispatcher

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
