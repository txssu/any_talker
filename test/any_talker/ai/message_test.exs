defmodule AnyTalker.AI.MessageTest do
  use ExUnit.Case, async: true

  alias AnyTalker.AI.Message

  describe "format_list/1" do
    test "returns chronological order on reverse input" do
      messages = [
        message("3", id: 3),
        message("2", id: 2),
        message("1", id: 1)
      ]

      expected = [
        %{content: ~s({"text":"1","sent_at":"2024-01-01T17:00:00+05:00"}), role: :assistant},
        %{content: ~s({"text":"2","sent_at":"2024-01-01T17:00:00+05:00"}), role: :assistant},
        %{content: ~s({"text":"3","sent_at":"2024-01-01T17:00:00+05:00"}), role: :assistant}
      ]

      assert expected == Message.format_list(messages)
    end

    test "appends username on user message" do
      messages = [
        message("TestText", role: :user, username: "TestUser")
      ]

      assert [msg] = Message.format_list(messages)
      json_content = Jason.decode!(msg.content)
      assert json_content["username"] == "TestUser"
      assert json_content["text"] == "TestText"
    end

    test "always includes sent_at in message" do
      sent_at = ~U[2024-01-01 12:00:00Z]

      messages = [
        message("TestText", role: :user, sent_at: sent_at)
      ]

      assert [msg] = Message.format_list(messages)
      json_content = Jason.decode!(msg.content)
      assert json_content["text"] == "TestText"
      assert json_content["sent_at"] == "2024-01-01T17:00:00+05:00"
    end

    test "appends reply to assistant message before current" do
      reply = message("1", role: :assistant, id: 1)

      messages = [
        message("2", role: :assistant, reply: reply, id: 2)
      ]

      expected = [
        %{content: ~s({"text":"1","sent_at":"2024-01-01T17:00:00+05:00"}), role: :assistant},
        %{content: ~s({"text":"2","sent_at":"2024-01-01T17:00:00+05:00"}), role: :assistant}
      ]

      assert expected == Message.format_list(messages)
    end

    test "appends reply to assistant message between current ans previous" do
      reply = message("2", role: :assistant, id: 2)

      messages = [
        message("3", role: :assistant, reply: reply, id: 3),
        message("1", role: :assistant, id: 1)
      ]

      expected = [
        %{content: ~s({"text":"1","sent_at":"2024-01-01T17:00:00+05:00"}), role: :assistant},
        %{content: ~s({"text":"2","sent_at":"2024-01-01T17:00:00+05:00"}), role: :assistant},
        %{content: ~s({"text":"3","sent_at":"2024-01-01T17:00:00+05:00"}), role: :assistant}
      ]

      assert expected == Message.format_list(messages)
    end

    test "appends reply to user message before current" do
      reply = message("1", role: :user, username: "User1", id: 1)

      messages = [
        message("2", role: :user, username: "User2", reply: reply, id: 2)
      ]

      assert [msg1, msg2] = Message.format_list(messages)

      json1 = Jason.decode!(msg1.content)
      json2 = Jason.decode!(msg2.content)

      assert json1["username"] == "User1"
      assert json1["text"] == "1"
      assert json1["sent_at"] == "2024-01-01T17:00:00+05:00"
      assert json2["username"] == "User2"
      assert json2["text"] == "2"
      assert json2["sent_at"] == "2024-01-01T17:00:00+05:00"
    end

    test "does not append reply if already in list" do
      reply = message("1", role: :assistant, id: 1)

      messages = [
        message("2", role: :assistant, reply: reply, id: 2),
        reply
      ]

      expected = [
        %{content: ~s({"text":"1","sent_at":"2024-01-01T17:00:00+05:00"}), role: :assistant},
        %{content: ~s({"text":"2","sent_at":"2024-01-01T17:00:00+05:00"}), role: :assistant}
      ]

      assert expected == Message.format_list(messages)
    end

    test "appends reply with quote when provided" do
      reply = message("1", role: :assistant, quote: "One", id: 1)

      messages = [
        message("2", role: :assistant, reply: reply, id: 2)
      ]

      assert [msg1, msg2] = Message.format_list(messages)

      json1 = Jason.decode!(msg1.content)
      json2 = Jason.decode!(msg2.content)

      assert json1["text"] == "1"
      assert json1["sent_at"] == "2024-01-01T17:00:00+05:00"
      assert json2["text"] == "2"
      assert json2["sent_at"] == "2024-01-01T17:00:00+05:00"
      assert json2["quote"] == "One"
    end

    test "append only quote reply if already in list" do
      reply = message("1", role: :assistant, quote: "One", id: 1)

      messages = [
        message("2", role: :assistant, reply: reply, id: 2),
        reply
      ]

      assert [msg1, msg2] = Message.format_list(messages)

      json1 = Jason.decode!(msg1.content)
      json2 = Jason.decode!(msg2.content)

      assert json1["text"] == "1"
      assert json1["sent_at"] == "2024-01-01T17:00:00+05:00"
      assert json2["text"] == "2"
      assert json2["sent_at"] == "2024-01-01T17:00:00+05:00"
      assert json2["quote"] == "One"
    end

    test "handles image_url with JSON text and image attachment" do
      messages = [
        message("Test text", role: :user, image_url: "https://example.com/image.jpg", id: 1)
      ]

      assert [msg] = Message.format_list(messages)

      # Should return array with JSON text and image
      assert is_list(msg.content)
      assert length(msg.content) == 2

      text_content = Enum.find(msg.content, &(&1[:type] == "input_text"))
      image_content = Enum.find(msg.content, &(&1[:type] == "input_image"))

      # Text should be JSON
      json_data = Jason.decode!(text_content[:text])
      assert json_data["text"] == "Test text"

      # Image should have proper structure (original format)
      assert image_content[:image_url] == "https://example.com/image.jpg"
    end

    test "handles image-only message with JSON and image attachment" do
      messages = [
        message(nil, role: :user, image_url: "https://example.com/image.jpg", id: 1)
      ]

      assert [msg] = Message.format_list(messages)

      # Should return array with JSON text and image
      assert is_list(msg.content)
      assert length(msg.content) == 2

      text_content = Enum.find(msg.content, &(&1[:type] == "input_text"))
      image_content = Enum.find(msg.content, &(&1[:type] == "input_image"))

      # Text should be JSON (even if empty)
      json_data = Jason.decode!(text_content[:text])
      assert is_map(json_data)

      # Image should have proper structure (original format)
      assert image_content[:image_url] == "https://example.com/image.jpg"
    end

    test "handles image with username and quote in JSON" do
      reply = message("Original", role: :user, quote: "Quoted text", id: 1)

      messages = [
        message("Response text",
          role: :user,
          username: "TestUser",
          reply: reply,
          image_url: "https://example.com/image.jpg",
          id: 2
        )
      ]

      assert [msg1, msg2] = Message.format_list(messages)

      # First message (reply)
      json1 = Jason.decode!(msg1.content)
      assert json1["text"] == "Original"

      # Second message with image - should be array format
      assert is_list(msg2.content)
      assert length(msg2.content) == 2

      text_content = Enum.find(msg2.content, &(&1[:type] == "input_text"))
      image_content = Enum.find(msg2.content, &(&1[:type] == "input_image"))

      # JSON should contain all metadata
      json_data = Jason.decode!(text_content[:text])
      assert json_data["text"] == "Response text"
      assert json_data["username"] == "TestUser"
      assert json_data["quote"] == "Quoted text"

      # Image should have proper structure (original format)
      assert image_content[:image_url] == "https://example.com/image.jpg"
    end
  end

  defp message(text, options) do
    id = Keyword.get_lazy(options, :id, &System.unique_integer/0)
    role = Keyword.get(options, :role, :assistant)
    sent_at = Keyword.get(options, :sent_at, ~U[2024-01-01 12:00:00Z])

    Message.new(id, role, text, sent_at, options)
  end
end
