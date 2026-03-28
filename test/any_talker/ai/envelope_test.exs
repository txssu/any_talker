defmodule AnyTalker.AI.EnvelopeTest do
  use AnyTalker.DataCase, async: true

  alias AnyTalker.AI.Envelope
  alias AnyTalker.AI.History.Key
  alias AnyTalker.AI.History.Storable

  describe "Storable.to_key/1" do
    test "returns key with user id for inline source" do
      envelope = %Envelope{
        source: :inline,
        author: %{id: 42},
        reply: nil
      }

      assert Storable.to_key(envelope) == Key.new(42, nil)
    end

    test "returns empty key when reply is nil and source is chat" do
      envelope = %Envelope{source: :chat, reply: nil}

      assert Storable.to_key(envelope) == Key.new()
    end

    test "returns empty key when reply is nil and source is default" do
      envelope = %Envelope{reply: nil}

      assert Storable.to_key(envelope) == Key.new()
    end
  end
end
