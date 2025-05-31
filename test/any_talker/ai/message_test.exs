defmodule AnyTalker.AI.MessageTest do
  use ExUnit.Case, async: true

  alias AnyTalker.AI.Message

  describe "format_list/1" do
    test "returns chronological order on reverse input" do
      messages = [
        message("3"),
        message("2"),
        message("1")
      ]

      expected = [
        %{content: "1", role: :system},
        %{content: "2", role: :system},
        %{content: "3", role: :system}
      ]

      assert expected == Message.format_list(messages)
    end

    test "appends username on user message" do
      messages = [
        message("TestText", role: :user, username: "TestUser")
      ]

      assert [msg_username, msg_text] = Message.format_list(messages)
      assert msg_username.content =~ "TestUser"
      assert msg_text.content =~ "TestText"
    end

    test "appends reply to assistant message before current" do
      reply = message("1", role: :assistant)

      messages = [
        message("2", role: :assistant, reply: reply)
      ]

      expected = [
        %{content: "1", role: :assistant},
        %{content: "2", role: :assistant}
      ]

      assert expected == Message.format_list(messages)
    end

    test "appends reply to assistant message between current ans previous" do
      reply = message("2", role: :assistant)

      messages = [
        message("3", role: :assistant, reply: reply),
        message("1", role: :assistant)
      ]

      expected = [
        %{content: "1", role: :assistant},
        %{content: "2", role: :assistant},
        %{content: "3", role: :assistant}
      ]

      assert expected == Message.format_list(messages)
    end

    test "appends reply to user message before current" do
      reply = message("1", role: :user, username: "User1")

      messages = [
        message("2", role: :user, username: "User2", reply: reply)
      ]

      assert [
               %{content: username1, role: :system},
               %{content: "1", role: :user},
               %{content: username2, role: :system},
               %{content: "2", role: :user}
             ] = Message.format_list(messages)

      assert username1 =~ "User1"
      assert username2 =~ "User2"
    end

    test "does not append reply if already in list" do
      reply = message("1", role: :assistant)

      messages = [
        message("2", role: :assistant, reply: reply),
        reply
      ]

      expected = [
        %{content: "1", role: :assistant},
        %{content: "2", role: :assistant}
      ]

      assert expected == Message.format_list(messages)
    end

    test "appends reply with quote when provided" do
      reply = message("1", role: :assistant, quote: "One")

      messages = [
        message("2", role: :assistant, reply: reply)
      ]

      assert [
               %{content: "1", role: :assistant},
               %{content: quoted_text, role: :system},
               %{content: "2", role: :assistant}
             ] = Message.format_list(messages)

      assert quoted_text =~ "One"
    end

    test "append only quote reply if already in list" do
      reply = message("1", role: :assistant, quote: "One")

      messages = [
        message("2", role: :assistant, reply: reply),
        reply
      ]

      assert [
               %{content: "1", role: :assistant},
               %{content: quoted_text, role: :system},
               %{content: "2", role: :assistant}
             ] = Message.format_list(messages)

      assert quoted_text =~ "One"
    end
  end

  defp message(text, options \\ []) do
    id = Keyword.get_lazy(options, :id, &System.unique_integer/0)
    role = Keyword.get(options, :role, :system)

    Message.new(id, role, text, options)
  end
end
