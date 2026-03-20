defmodule AnyTalker.RSS.FeedFetcherTest do
  use ExUnit.Case, async: true

  alias AnyTalker.RSS.FeedFetcher

  @rss_body """
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>RSS Feed</title>
      <item>
        <title>RSS Article</title>
        <link>https://example.com/rss-1</link>
        <description>RSS content</description>
        <pubDate>Mon, 10 Mar 2025 12:00:00 +0000</pubDate>
      </item>
    </channel>
  </rss>
  """

  @atom_body """
  <?xml version="1.0" encoding="utf-8"?>
  <feed xmlns="http://www.w3.org/2005/Atom">
    <title>Atom Feed</title>
    <link href="https://example.com/" rel="alternate"/>
    <id>urn:uuid:example</id>
    <updated>2025-03-10T12:00:00Z</updated>
    <entry>
      <title>Atom Article</title>
      <link href="https://example.com/atom-1" rel="alternate"/>
      <id>urn:uuid:1</id>
      <updated>2025-03-10T12:00:00Z</updated>
      <published>2025-03-10T10:00:00Z</published>
      <content type="html">Atom content</content>
    </entry>
  </feed>
  """

  setup do
    Repatch.setup()
    :ok
  end

  test "parses RSS feed" do
    Repatch.patch(Tesla, :get, fn _client, _url ->
      {:ok, %Tesla.Env{status: 200, body: @rss_body}}
    end)

    assert {:ok, result} = FeedFetcher.fetch_and_parse("https://example.com/feed")
    assert result.title == "RSS Feed"
    assert [entry] = result.entries
    assert entry.url == "https://example.com/rss-1"
    assert entry.guid == "https://example.com/rss-1"
    assert entry.title == "RSS Article"
    assert entry.content == "RSS content"
    assert %DateTime{} = entry.published_at
  end

  test "parses Atom feed" do
    Repatch.patch(Tesla, :get, fn _client, _url ->
      {:ok, %Tesla.Env{status: 200, body: @atom_body}}
    end)

    assert {:ok, result} = FeedFetcher.fetch_and_parse("https://example.com/feed")
    assert result.title == "Atom Feed"
    assert [entry] = result.entries
    assert entry.url == "https://example.com/atom-1"
    assert entry.guid == "urn:uuid:1"
    assert entry.title == "Atom Article"
    assert entry.content == "Atom content"
    assert %DateTime{} = entry.published_at
  end

  test "returns error for invalid feed body" do
    Repatch.patch(Tesla, :get, fn _client, _url ->
      {:ok, %Tesla.Env{status: 200, body: "not a feed"}}
    end)

    assert {:error, :invalid_feed} = FeedFetcher.fetch_and_parse("https://example.com/bad")
  end

  test "returns error on HTTP failure" do
    Repatch.patch(Tesla, :get, fn _client, _url ->
      {:ok, %Tesla.Env{status: 404, body: "Not found"}}
    end)

    assert {:error, {:http_status, 404}} = FeedFetcher.fetch_and_parse("https://example.com/404")
  end

  test "RSS entry uses guid element when present" do
    rss_with_guid = """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
      <channel>
        <title>RSS Feed</title>
        <item>
          <title>Article</title>
          <link>https://example.com/post/slug-may-change/123</link>
          <guid>https://example.com/post/123</guid>
          <description>Content</description>
        </item>
      </channel>
    </rss>
    """

    Repatch.patch(Tesla, :get, fn _client, _url ->
      {:ok, %Tesla.Env{status: 200, body: rss_with_guid}}
    end)

    assert {:ok, result} = FeedFetcher.fetch_and_parse("https://example.com/feed")
    assert [entry] = result.entries
    assert entry.guid == "https://example.com/post/123"
    assert entry.url == "https://example.com/post/slug-may-change/123"
  end

  test "Atom entry uses summary when content is absent" do
    atom_with_summary = """
    <?xml version="1.0" encoding="utf-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <title>Summary Feed</title>
      <id>urn:uuid:sf</id>
      <updated>2025-03-10T12:00:00Z</updated>
      <entry>
        <title>Summary Entry</title>
        <link href="https://example.com/s1" rel="alternate"/>
        <id>urn:uuid:s1</id>
        <updated>2025-03-10T12:00:00Z</updated>
        <summary>Summary text only</summary>
      </entry>
    </feed>
    """

    Repatch.patch(Tesla, :get, fn _client, _url ->
      {:ok, %Tesla.Env{status: 200, body: atom_with_summary}}
    end)

    assert {:ok, result} = FeedFetcher.fetch_and_parse("https://example.com/feed")
    assert [entry] = result.entries
    assert entry.content == "Summary text only"
  end
end
