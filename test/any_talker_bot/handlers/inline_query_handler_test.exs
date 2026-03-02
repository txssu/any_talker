defmodule AnyTalkerBot.Handlers.InlineQueryHandlerTest do
  use ExUnit.Case, async: true

  alias AnyTalkerBot.Handlers.InlineQueryHandler

  describe "query type detection" do
    test "empty string is :empty" do
      assert InlineQueryHandler.query_type("") == :empty
    end

    test "whitespace-only is :empty" do
      assert InlineQueryHandler.query_type("   ") == :empty
    end

    test "https URL is :ask" do
      assert InlineQueryHandler.query_type("https://example.com/page") == :ask
    end

    test ".com domain is :ask" do
      assert InlineQueryHandler.query_type("example.com") == :ask
    end

    test "three words with numeric last word is :currency" do
      assert InlineQueryHandler.query_type("usd rub 100") == :currency
    end

    test "three words with k shortcut is :currency" do
      assert InlineQueryHandler.query_type("usd rub 10k") == :currency
    end

    test "three words with kk shortcut is :currency" do
      assert InlineQueryHandler.query_type("usd rub 5kk") == :currency
    end

    test "two words is :ask" do
      assert InlineQueryHandler.query_type("купить яндекс") == :ask
    end

    test "plain sentence is :ask" do
      assert InlineQueryHandler.query_type("как работает квантовый компьютер") == :ask
    end

    test "three words where last is not a number is :ask" do
      assert InlineQueryHandler.query_type("usd rub notanumber") == :ask
    end
  end
end
