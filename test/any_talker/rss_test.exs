defmodule AnyTalker.RSSTest do
  use AnyTalker.DataCase, async: true

  import AnyTalker.AccountsFixtures

  alias AnyTalker.RSS
  alias AnyTalker.RSS.Article
  alias AnyTalker.RSS.Feed
  alias AnyTalker.RSS.FetchFeedJob
  alias AnyTalker.RSS.Group
  alias AnyTalker.RSS.ReadStatus
  alias AnyTalker.RSS.Subscription

  defp create_feed(url \\ "https://example.com/feed.xml") do
    {:ok, feed} = Repo.insert(%Feed{url: url, title: "Example Feed"})
    feed
  end

  defp create_article(feed, attrs \\ %{}) do
    unique = System.unique_integer()
    url = Map.get(attrs, :url, "https://example.com/#{unique}")
    guid = Map.get(attrs, :guid, "guid-#{unique}")
    {:ok, article} = Repo.insert(%Article{feed_id: feed.id, url: url, guid: guid, title: "Test Article"})
    article
  end

  describe "create_group/2" do
    test "creates a group for a user" do
      user = user_fixture()
      assert {:ok, %Group{name: "Tech"}} = RSS.create_group(user.id, "Tech")
    end

    test "returns error for duplicate group name" do
      user = user_fixture()
      RSS.create_group(user.id, "Tech")
      assert {:error, _changeset} = RSS.create_group(user.id, "Tech")
    end

    test "same name is allowed for different users" do
      user1 = user_fixture()
      user2 = user_fixture()
      assert {:ok, _group} = RSS.create_group(user1.id, "Tech")
      assert {:ok, _group} = RSS.create_group(user2.id, "Tech")
    end
  end

  describe "delete_group/2" do
    test "deletes group and its subscriptions" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})

      assert :ok = RSS.delete_group(user.id, group.id)
      assert Repo.get(Group, group.id) == nil
      assert Repo.all(Subscription) == []
    end

    test "returns error when group does not belong to user" do
      user1 = user_fixture()
      user2 = user_fixture()
      {:ok, group} = RSS.create_group(user1.id, "Tech")

      assert {:error, :not_found} = RSS.delete_group(user2.id, group.id)
    end
  end

  describe "get_or_create_default_group/1" do
    test "creates Default group on first call" do
      user = user_fixture()
      {:ok, group} = RSS.get_or_create_default_group(user.id)
      assert group.name == "Default"
    end

    test "returns existing Default group on subsequent calls" do
      user = user_fixture()
      {:ok, group1} = RSS.get_or_create_default_group(user.id)
      {:ok, group2} = RSS.get_or_create_default_group(user.id)
      assert group1.id == group2.id
    end
  end

  describe "list_groups/1" do
    test "returns groups with unread counts" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      _article = create_article(feed)

      groups = RSS.list_groups(user.id)
      assert [{^group, 1}] = groups
    end

    test "read articles are not counted" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      article = create_article(feed)
      Repo.insert!(%ReadStatus{user_id: user.id, article_id: article.id})

      groups = RSS.list_groups(user.id)
      assert [{^group, 0}] = groups
    end

    test "articles older than 48 hours are not counted as unread" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      article = create_article(feed)

      old_time = DateTime.add(DateTime.utc_now(), -73, :hour)
      query = from(a in Article, where: a.id == ^article.id)
      Repo.update_all(query, set: [inserted_at: old_time])

      groups = RSS.list_groups(user.id)
      assert [{^group, 0}] = groups
    end
  end

  describe "subscribe/3" do
    test "creates a subscription and marks existing articles as read" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      _article = create_article(feed)

      assert {:ok, %Subscription{}} = RSS.subscribe(user.id, feed.url, group.id)

      # Existing article should be marked read
      query = from rs in ReadStatus, where: rs.user_id == ^user.id
      assert Repo.one(query)
    end

    test "returns error for duplicate subscription" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()

      RSS.subscribe(user.id, feed.url, group.id)
      assert {:error, :already_subscribed} = RSS.subscribe(user.id, feed.url, group.id)
    end

    test "returns error when group does not belong to user" do
      user1 = user_fixture()
      user2 = user_fixture()
      {:ok, group} = RSS.create_group(user1.id, "Tech")
      feed = create_feed()

      assert {:error, :group_not_found} = RSS.subscribe(user2.id, feed.url, group.id)
    end

    test "creates feed record if it does not exist yet" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")

      assert {:ok, _subscription} = RSS.subscribe(user.id, "https://new-feed.com/rss", group.id)
      assert Repo.get_by(Feed, url: "https://new-feed.com/rss")
    end

    test "fetches and saves articles when subscribing to a new feed URL" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")

      Process.put(
        :stub_feed_fetcher_result,
        {:ok,
         %{
           title: "My Feed",
           entries: [
             %{
               url: "https://example.com/article-1",
               guid: "guid-1",
               title: "Article 1",
               content: "Body 1",
               published_at: nil
             },
             %{
               url: "https://example.com/article-2",
               guid: "guid-2",
               title: "Article 2",
               content: "Body 2",
               published_at: nil
             }
           ]
         }}
      )

      assert {:ok, %Subscription{}} = RSS.subscribe(user.id, "https://new-feed.com/rss", group.id)

      # Feed created with title from fetch
      feed = Repo.get_by!(Feed, url: "https://new-feed.com/rss")
      assert feed.title == "My Feed"

      # Articles saved
      articles =
        Article
        |> where([a], a.feed_id == ^feed.id)
        |> Repo.all()

      assert length(articles) == 2

      # All articles marked as read
      read_statuses =
        ReadStatus
        |> where([rs], rs.user_id == ^user.id)
        |> Repo.all()

      assert length(read_statuses) == 2
    end

    test "returns error and creates nothing when fetch fails for new URL" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")

      Process.put(:stub_feed_fetcher_result, {:error, :timeout})

      assert {:error, :fetch_failed} = RSS.subscribe(user.id, "https://bad-feed.com/rss", group.id)

      # No feed created
      assert is_nil(Repo.get_by(Feed, url: "https://bad-feed.com/rss"))
    end

    test "skips fetch for already-known feed URLs" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      _feed = create_feed("https://known-feed.com/rss")

      # Set stub to fail — shouldn't matter since fetch is skipped for existing URLs
      Process.put(:stub_feed_fetcher_result, {:error, :should_not_be_called})

      assert {:ok, %Subscription{}} = RSS.subscribe(user.id, "https://known-feed.com/rss", group.id)
    end
  end

  describe "unsubscribe/2" do
    test "removes all subscriptions for the feed across all groups" do
      user = user_fixture()
      {:ok, group1} = RSS.create_group(user.id, "Tech")
      {:ok, group2} = RSS.create_group(user.id, "News")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group1.id})
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group2.id})

      assert :ok = RSS.unsubscribe(user.id, feed.url)
      assert Repo.all(Subscription) == []
    end

    test "returns :ok even when no subscription exists" do
      user = user_fixture()
      assert :ok = RSS.unsubscribe(user.id, "https://example.com/feed.xml")
    end
  end

  describe "list_unread/2" do
    test "returns unread articles in a group" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      article = create_article(feed)

      articles = RSS.list_unread(user.id, group.id)
      assert [^article] = articles
    end

    test "does not return read articles" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      article = create_article(feed)
      Repo.insert!(%ReadStatus{user_id: user.id, article_id: article.id})

      assert [] = RSS.list_unread(user.id, group.id)
    end

    test "does not return articles from other groups" do
      user = user_fixture()
      {:ok, group1} = RSS.create_group(user.id, "Tech")
      {:ok, group2} = RSS.create_group(user.id, "News")
      feed1 = create_feed("https://tech.com/feed")
      feed2 = create_feed("https://news.com/feed")
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed1.id, group_id: group1.id})
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed2.id, group_id: group2.id})
      _tech_article = create_article(feed1)
      news_article = create_article(feed2)

      articles = RSS.list_unread(user.id, group2.id)
      assert [^news_article] = articles
    end

    test "does not return articles older than 48 hours" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      article = create_article(feed)

      old_time = DateTime.add(DateTime.utc_now(), -73, :hour)
      query = from(a in Article, where: a.id == ^article.id)
      Repo.update_all(query, set: [inserted_at: old_time])

      assert [] = RSS.list_unread(user.id, group.id)
    end
  end

  describe "list_unread_all/1" do
    test "returns unread articles across all groups" do
      user = user_fixture()
      {:ok, group1} = RSS.create_group(user.id, "Tech")
      {:ok, group2} = RSS.create_group(user.id, "News")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group1.id})
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group2.id})
      article = create_article(feed)

      articles = RSS.list_unread_all(user.id)
      # Same article via two subscriptions — should appear once
      assert length(articles) == 1
      assert hd(articles).id == article.id
    end

    test "does not return articles older than 48 hours" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      article = create_article(feed)

      old_time = DateTime.add(DateTime.utc_now(), -73, :hour)
      query = from(a in Article, where: a.id == ^article.id)
      Repo.update_all(query, set: [inserted_at: old_time])

      assert [] = RSS.list_unread_all(user.id)
    end
  end

  describe "mark_read/2" do
    test "inserts read statuses for given article IDs" do
      user = user_fixture()
      feed = create_feed()
      article = create_article(feed)

      RSS.mark_read(user.id, [article.id])

      assert Repo.get_by(ReadStatus, user_id: user.id, article_id: article.id)
    end

    test "is idempotent" do
      user = user_fixture()
      feed = create_feed()
      article = create_article(feed)

      RSS.mark_read(user.id, [article.id])
      RSS.mark_read(user.id, [article.id])

      query = from(rs in ReadStatus, where: rs.user_id == ^user.id)
      count = Repo.aggregate(query, :count, :id)

      assert count == 1
    end
  end

  describe "mark_all_read/2" do
    test "marks all unread articles as read" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      create_article(feed)
      create_article(feed)

      RSS.mark_all_read(user.id, nil)

      assert [] = RSS.list_unread_all(user.id)
    end

    test "with group_id only marks articles in that group" do
      user = user_fixture()
      {:ok, group1} = RSS.create_group(user.id, "Tech")
      {:ok, group2} = RSS.create_group(user.id, "News")
      feed1 = create_feed("https://tech.com/feed")
      feed2 = create_feed("https://news.com/feed")
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed1.id, group_id: group1.id})
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed2.id, group_id: group2.id})
      _tech_article = create_article(feed1)
      news_article = create_article(feed2)

      RSS.mark_all_read(user.id, group1.id)

      assert [^news_article] = RSS.list_unread(user.id, group2.id)
      assert [] = RSS.list_unread(user.id, group1.id)
    end

    test "does not mark articles older than 48 hours (they are already auto-read)" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      article = create_article(feed)

      old_time = DateTime.add(DateTime.utc_now(), -73, :hour)
      article_query = from a in Article, where: a.id == ^article.id
      Repo.update_all(article_query, set: [inserted_at: old_time])
      RSS.mark_all_read(user.id, nil)

      query = from rs in ReadStatus, where: rs.user_id == ^user.id
      assert Repo.all(query) == []
    end

    test "is idempotent" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      create_article(feed)

      RSS.mark_all_read(user.id, nil)
      RSS.mark_all_read(user.id, nil)

      query = from rs in ReadStatus, where: rs.user_id == ^user.id
      assert length(Repo.all(query)) == 1
    end
  end

  describe "guid deduplication" do
    test "re-fetch does not create duplicate articles when URL changes but guid stays the same" do
      Repatch.setup()

      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")

      Process.put(
        :stub_feed_fetcher_result,
        {:ok,
         %{
           title: "My Feed",
           entries: [
             %{
               url: "https://example.com/t/old-slug/1",
               guid: "stable-guid-1",
               title: "Original Title",
               content: "Body",
               published_at: nil
             }
           ]
         }}
      )

      assert {:ok, _sub} = RSS.subscribe(user.id, "https://feed.example.com/rss", group.id)

      feed = Repo.get_by!(Feed, url: "https://feed.example.com/rss")

      initial_articles =
        Article
        |> where([a], a.feed_id == ^feed.id)
        |> Repo.all()

      assert length(initial_articles) == 1
      assert hd(initial_articles).url == "https://example.com/t/old-slug/1"

      # Re-fetch via the production code path with changed URL/title but same guid
      updated_rss = """
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0">
        <channel>
          <title>My Feed</title>
          <item>
            <title>Updated Title</title>
            <link>https://example.com/t/new-slug/1</link>
            <guid>stable-guid-1</guid>
            <description>Updated Body</description>
          </item>
        </channel>
      </rss>
      """

      Repatch.patch(Tesla, :get, fn _client, _url ->
        {:ok, %Tesla.Env{status: 200, body: updated_rss}}
      end)

      assert :ok = FetchFeedJob.perform(%Oban.Job{args: %{"feed_id" => feed.id}})

      updated_articles =
        Article
        |> where([a], a.feed_id == ^feed.id)
        |> Repo.all()

      assert length(updated_articles) == 1
      assert hd(updated_articles).url == "https://example.com/t/new-slug/1"
      assert hd(updated_articles).title == "Updated Title"
      assert hd(updated_articles).content == "Updated Body"
    end
  end

  describe "get_group_by_name/2" do
    test "returns the group when found" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      assert RSS.get_group_by_name(user.id, "Tech") == group
    end

    test "returns nil when not found" do
      user = user_fixture()
      assert RSS.get_group_by_name(user.id, "Missing") == nil
    end

    test "does not return groups from another user" do
      user1 = user_fixture()
      user2 = user_fixture()
      {:ok, group1} = RSS.create_group(user1.id, "Tech")
      {:ok, group2} = RSS.create_group(user2.id, "Tech")

      assert RSS.get_group_by_name(user1.id, "Tech").id == group1.id
      assert RSS.get_group_by_name(user2.id, "Tech").id == group2.id
    end
  end

  describe "list_feeds/2" do
    test "returns feeds subscribed to in a group" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})

      feeds = RSS.list_feeds(user.id, group.id)
      assert [^feed] = feeds
    end

    test "does not return feeds from other groups" do
      user = user_fixture()
      {:ok, group1} = RSS.create_group(user.id, "Tech")
      {:ok, group2} = RSS.create_group(user.id, "News")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group1.id})

      assert [] = RSS.list_feeds(user.id, group2.id)
    end
  end

  describe "list_articles/4" do
    test "returns articles with read? false for unread" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      _article = create_article(feed)

      {articles, total} = RSS.list_articles(user.id, group.id, 0)

      assert total == 1
      assert [%{read?: false}] = articles
    end

    test "returns articles with read? true for read articles" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      article = create_article(feed)
      Repo.insert!(%ReadStatus{user_id: user.id, article_id: article.id})

      {articles, total} = RSS.list_articles(user.id, group.id, 0)

      assert total == 1
      assert [%{read?: true}] = articles
    end

    test "returns articles with read? true for articles older than 48 hours" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      article = create_article(feed)

      old_time = DateTime.add(DateTime.utc_now(), -73, :hour)
      query = from(a in Article, where: a.id == ^article.id)
      Repo.update_all(query, set: [inserted_at: old_time])

      {articles, _total} = RSS.list_articles(user.id, group.id, 0)
      assert [%{read?: true}] = articles
    end

    test "paginates results" do
      user = user_fixture()
      {:ok, group} = RSS.create_group(user.id, "Tech")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group.id})
      for _i <- 1..20, do: create_article(feed)

      {page0, total} = RSS.list_articles(user.id, group.id, 0)
      {page1, _total} = RSS.list_articles(user.id, group.id, 1)

      assert total == 20
      assert length(page0) == 15
      assert length(page1) == 5
    end

    test "with nil group_id returns articles from all subscribed feeds" do
      user = user_fixture()
      {:ok, group1} = RSS.create_group(user.id, "Tech")
      {:ok, group2} = RSS.create_group(user.id, "News")
      feed1 = create_feed("https://tech.com/feed")
      feed2 = create_feed("https://news.com/feed")
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed1.id, group_id: group1.id})
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed2.id, group_id: group2.id})
      create_article(feed1)
      create_article(feed2)

      {articles, total} = RSS.list_articles(user.id, nil, 0)

      assert total == 2
      assert length(articles) == 2
    end

    test "same article via multiple group subscriptions appears only once" do
      user = user_fixture()
      {:ok, group1} = RSS.create_group(user.id, "Tech")
      {:ok, group2} = RSS.create_group(user.id, "News")
      feed = create_feed()
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group1.id})
      Repo.insert!(%Subscription{user_id: user.id, feed_id: feed.id, group_id: group2.id})
      create_article(feed)

      {articles, total} = RSS.list_articles(user.id, nil, 0)

      assert total == 1
      assert length(articles) == 1
    end
  end
end
