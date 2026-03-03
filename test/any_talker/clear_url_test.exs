defmodule AnyTalker.ClearUrlTest do
  use ExUnit.Case, async: true

  alias AnyTalker.ClearUrl

  describe "clean/1" do
    test "removes tracking params from Amazon URL" do
      url = "https://www.amazon.com/dp/B01N5IB20Q?tag=foo&qid=123&sprefix=abc&dchild=1"

      assert ClearUrl.clean(url) == "https://www.amazon.com/dp/B01N5IB20Q"
    end

    test "removes rawRules patterns from Amazon URL" do
      url = "https://www.amazon.com/dp/B01N5IB20Q/ref=sr_1_1"

      assert ClearUrl.clean(url) == "https://www.amazon.com/dp/B01N5IB20Q"
    end

    test "removes utm parameters from Google URL" do
      url = "https://www.google.com/search?q=elixir&utm_source=twitter&utm_medium=social"

      result = ClearUrl.clean(url)

      assert result == "https://www.google.com/search?q=elixir"
    end

    test "preserves URL without tracking params" do
      url = "https://example.com/page?id=42"

      assert ClearUrl.clean(url) == url
    end

    test "preserves URL that matches no provider" do
      url = "https://my-personal-site.test/hello"

      assert ClearUrl.clean(url) == url
    end

    test "handles URL with no query string" do
      url = "https://www.amazon.com/dp/B01N5IB20Q"

      assert ClearUrl.clean(url) == url
    end

    test "keeps non-tracking params while removing tracking ones" do
      url = "https://www.amazon.com/dp/B01N5IB20Q?th=1&m=seller123"

      result = ClearUrl.clean(url)

      assert result =~ "m=seller123"
      refute result =~ "th="
    end
  end
end
