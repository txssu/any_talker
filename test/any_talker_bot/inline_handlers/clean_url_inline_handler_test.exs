defmodule AnyTalkerBot.InlineHandlers.CleanUrlInlineHandlerTest do
  use AnyTalker.DataCase, async: true

  import AnyTalkerBot.BotFixtures

  alias AnyTalkerBot.InlineHandlers.CleanUrlInlineHandler
  alias ExGram.Model.InlineQuery

  describe "match?/1" do
    test "matches http URLs" do
      assert CleanUrlInlineHandler.match?("check http://example.com")
    end

    test "matches https URLs" do
      assert CleanUrlInlineHandler.match?("check https://example.com/page")
    end

    test "does not match plain text" do
      refute CleanUrlInlineHandler.match?("just some text")
    end
  end

  describe "build_results/1" do
    test "returns list with one article with cleaned URLs in blockquote" do
      query = %InlineQuery{
        id: "q1",
        from: user(),
        query: "Check https://www.amazon.com/dp/B01N5IB20Q?tag=foo&ref=bar please",
        offset: ""
      }

      assert [result] = CleanUrlInlineHandler.build_results(query)

      assert result.id == "clean_url"
      assert result.title == "Убрать трекеры из ссылок"
      assert result.input_message_content.message_text =~ "Вот текст без трекеров"
      assert result.input_message_content.message_text =~ "<blockquote>"
      assert result.input_message_content.message_text =~ "https://www.amazon.com/dp/B01N5IB20Q"
      refute result.input_message_content.message_text =~ "tag=foo"
    end

    test "preserves surrounding text while cleaning URLs" do
      query = %InlineQuery{
        id: "q2",
        from: user(),
        query: "Вот ссылка https://www.google.com/search?q=elixir&utm_source=tw и ещё текст",
        offset: ""
      }

      assert [result] = CleanUrlInlineHandler.build_results(query)

      msg = result.input_message_content.message_text
      assert msg =~ "Вот ссылка"
      assert msg =~ "и ещё текст"
      assert msg =~ "q=elixir"
      refute msg =~ "utm_source"
    end
  end
end
