defmodule AnyTalkerBot.RssCommandTest do
  use AnyTalker.DataCase, async: true

  import AnyTalker.AccountsFixtures

  alias AnyTalker.RSS
  alias AnyTalkerBot.RssCommand

  describe "handle_input/2" do
    test "empty input returns :show_groups" do
      user = user_fixture()
      assert {:show_groups, _groups} = RssCommand.handle_input("", user.id)
    end

    test "news command with no args returns {:news, nil, nil}" do
      user = user_fixture()
      assert {:news, nil, nil} = RssCommand.handle_input("news", user.id)
    end

    test "news command with known group returns {:news, group_name, group_id}" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      group_id = group.id
      assert {:news, "Tech", ^group_id} = RssCommand.handle_input("news Tech", user.id)
    end

    test "news command with unknown group returns :group_not_found error" do
      user = user_fixture()
      assert {:error, :group_not_found} = RssCommand.handle_input("news Missing", user.id)
    end

    test "read command marks all unread as read" do
      user = user_fixture()
      assert {:ok, :marked_read, nil} = RssCommand.handle_input("read", user.id)
    end

    test "read command with group marks group as read" do
      user = user_fixture()
      RSS.create_group(user.id, "Tech")
      assert {:ok, :marked_read, "Tech"} = RssCommand.handle_input("read Tech", user.id)
    end

    test "read command with unknown group returns error" do
      user = user_fixture()
      assert {:error, :group_not_found} = RssCommand.handle_input("read Missing", user.id)
    end

    test "add command with unknown group returns error" do
      user = user_fixture()
      result = RssCommand.handle_input("add https://example.com UnknownGroup", user.id)
      assert {:error, :group_not_found} = result
    end

    test "unknown command returns :not_found error" do
      user = user_fixture()
      assert {:error, :not_found, _suggestions} = RssCommand.handle_input("xyz", user.id)
    end

    test "add command creates subscription in default group" do
      user = user_fixture()
      result = RssCommand.handle_input("add https://example.com/feed.xml", user.id)
      assert {:ok, :subscribed, _feed_url, _group_name} = result
    end

    test "remove command unsubscribes from feed" do
      user = user_fixture()
      {:ok, group} = RSS.get_or_create_default_group(user.id)
      RSS.subscribe(user.id, "https://example.com/feed.xml", group.id)

      assert {:ok, :unsubscribed, "https://example.com/feed.xml"} =
               RssCommand.handle_input("remove https://example.com/feed.xml", user.id)
    end

    test "group new creates a group" do
      user = user_fixture()
      assert {:ok, :group_created, "MyGroup"} = RssCommand.handle_input("group new MyGroup", user.id)
    end

    test "group delete removes a group" do
      user = user_fixture()
      RSS.create_group(user.id, "Old")
      assert {:ok, :group_deleted, "Old"} = RssCommand.handle_input("group delete Old", user.id)
    end

    test "list command returns feeds for default group" do
      user = user_fixture()
      {:ok, group} = RSS.get_or_create_default_group(user.id)
      RSS.subscribe(user.id, "https://example.com/feed.xml", group.id)
      assert {:list, [_feed], "Default"} = RssCommand.handle_input("list", user.id)
    end

    test "list command with unknown group returns error" do
      user = user_fixture()
      assert {:error, :group_not_found} = RssCommand.handle_input("list Missing", user.id)
    end

    test "group new with duplicate name returns :group_already_exists" do
      user = user_fixture()
      RSS.create_group(user.id, "Tech")
      assert {:error, :group_already_exists} = RssCommand.handle_input("group new Tech", user.id)
    end

    test "summary command returns :summary tuple with articles and group name" do
      user = user_fixture()
      assert {:summary, [], nil, nil} = RssCommand.handle_input("summary", user.id)
    end

    test "add command with unreachable feed returns :fetch_failed error" do
      user = user_fixture()
      Process.put(:stub_feed_fetcher_result, {:error, :timeout})
      assert {:error, :fetch_failed} = RssCommand.handle_input("add https://bad.com/rss", user.id)
    end
  end
end
