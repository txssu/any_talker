defmodule AnyTalker.AI.HistoryTest do
  use AnyTalker.DataCase, async: true

  alias AnyTalker.AI.History
  alias AnyTalker.AI.History.Key
  alias AnyTalker.AI.Message

  describe "put/3 with TTL" do
    test "stores history that expires after TTL" do
      key = Key.new(999, nil)
      msg = Message.new(nil, "user", "hello", nil)
      history = History.append(History.new(), msg)

      History.put(key, history, ttl: 50)
      assert %History{} = History.get(key)

      Process.sleep(100)
      assert History.get(key) == History.new()
    end
  end

  describe "put/2 without TTL" do
    test "stores history without expiration" do
      key = Key.new(998, nil)
      msg = Message.new(nil, "user", "hello", nil)
      history = History.append(History.new(), msg)

      History.put(key, history)
      assert %History{} = History.get(key)
    end
  end

  describe "trim/2" do
    test "keeps only the last N messages" do
      msgs = for i <- 1..6, do: Message.new(nil, "user", "msg #{i}", nil)

      history = History.append(History.new(), msgs)
      trimmed = History.trim(history, 4)

      texts =
        trimmed
        |> History.messages()
        |> Enum.map(fn msg -> hd(msg.content).text end)

      assert texts == ["msg 3", "msg 4", "msg 5", "msg 6"]
    end

    test "does nothing when history has fewer messages than limit" do
      msgs = [Message.new(nil, "user", "msg 1", nil)]
      history = History.append(History.new(), msgs)

      assert History.trim(history, 10) == history
    end
  end
end
