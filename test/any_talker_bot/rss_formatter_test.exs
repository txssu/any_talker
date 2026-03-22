defmodule AnyTalkerBot.RssFormatterTest do
  use ExUnit.Case, async: true

  alias AnyTalker.RSS.Article
  alias AnyTalkerBot.RssFormatter

  defp make_article(opts \\ []) do
    %Article{
      url: Keyword.get(opts, :url, "https://example.com/article"),
      title: Keyword.get(opts, :title, "Test Article"),
      read?: Keyword.get(opts, :read?, false)
    }
  end

  describe "format_news_page/4" do
    test "formats unread article with filled bullet" do
      articles = [make_article(read?: false, url: "https://ex.com/1", title: "Hello")]
      {text, _keyboard} = RssFormatter.format_news_page(articles, 0, 1, nil)
      assert text =~ ~r/● <a href="https:\/\/ex\.com\/1">Hello<\/a>/
    end

    test "formats read article with empty bullet" do
      articles = [make_article(read?: true, url: "https://ex.com/1", title: "Hello")]
      {text, _keyboard} = RssFormatter.format_news_page(articles, 0, 1, nil)
      assert text =~ ~r/○ <a href="https:\/\/ex\.com\/1">Hello<\/a>/
    end

    test "escapes HTML in title" do
      articles = [make_article(title: "Hello <World> & Co", read?: false)]
      {text, _keyboard} = RssFormatter.format_news_page(articles, 0, 1, nil)
      assert text =~ "Hello &lt;World&gt; &amp; Co"
    end

    test "appends page footer" do
      articles = [make_article()]
      {text, _keyboard} = RssFormatter.format_news_page(articles, 0, 1, nil)
      assert text =~ "Страница 1 из 1"
    end

    test "single page has mark-read and refresh buttons" do
      articles = [make_article()]
      {_text, keyboard} = RssFormatter.format_news_page(articles, 0, 1, nil)
      assert %{inline_keyboard: [[read_btn], [refresh_btn]]} = keyboard
      assert read_btn.text == "Прочитано ✓"
      assert read_btn.callback_data == "rss_read:0"
      assert refresh_btn.text == "Обновить"
      assert refresh_btn.callback_data == "rss_refresh:0"
    end

    test "page 0 with multiple pages returns nav, mark-read, and refresh buttons" do
      articles = for i <- 1..15, do: make_article(url: "https://ex.com/#{i}")
      {_text, keyboard} = RssFormatter.format_news_page(articles, 0, 20, nil)
      assert %{inline_keyboard: [[nav_btn], [read_btn], [refresh_btn]]} = keyboard
      assert nav_btn.text == "Вперёд →"
      assert nav_btn.callback_data == "rss_news:1:0"
      assert read_btn.text == "Прочитано ✓"
      assert refresh_btn.text == "Обновить"
    end

    test "middle page returns nav, mark-read, and refresh buttons" do
      articles = for i <- 1..15, do: make_article(url: "https://ex.com/#{i}")
      {_text, keyboard} = RssFormatter.format_news_page(articles, 1, 45, nil)
      assert %{inline_keyboard: [[back_btn, fwd_btn], [read_btn], [refresh_btn]]} = keyboard
      assert back_btn.text == "← Назад"
      assert back_btn.callback_data == "rss_news:0:0"
      assert fwd_btn.text == "Вперёд →"
      assert fwd_btn.callback_data == "rss_news:2:0"
      assert read_btn.text == "Прочитано ✓"
      assert refresh_btn.text == "Обновить"
    end

    test "last page returns nav, mark-read, and refresh buttons" do
      articles = for i <- 1..5, do: make_article(url: "https://ex.com/#{i}")
      {_text, keyboard} = RssFormatter.format_news_page(articles, 1, 20, nil)
      assert %{inline_keyboard: [[nav_btn], [read_btn], [refresh_btn]]} = keyboard
      assert nav_btn.text == "← Назад"
      assert nav_btn.callback_data == "rss_news:0:0"
      assert read_btn.text == "Прочитано ✓"
      assert refresh_btn.text == "Обновить"
    end

    test "encodes group_id in callback data" do
      articles = for i <- 1..15, do: make_article(url: "https://ex.com/#{i}")
      {_text, keyboard} = RssFormatter.format_news_page(articles, 0, 20, 42)
      assert %{inline_keyboard: [[nav_btn], [read_btn], [refresh_btn]]} = keyboard
      assert nav_btn.callback_data == "rss_news:1:42"
      assert read_btn.callback_data == "rss_read:42"
      assert refresh_btn.callback_data == "rss_refresh:42"
    end
  end

  describe "mark_read_keyboard/1" do
    test "builds keyboard with mark-read button for nil group" do
      keyboard = RssFormatter.mark_read_keyboard(nil)
      assert %{inline_keyboard: [[btn]]} = keyboard
      assert btn.text == "Прочитано ✓"
      assert btn.callback_data == "rss_read:0"
    end

    test "builds keyboard with mark-read button for specific group" do
      keyboard = RssFormatter.mark_read_keyboard(7)
      assert %{inline_keyboard: [[btn]]} = keyboard
      assert btn.callback_data == "rss_read:7"
    end
  end
end
