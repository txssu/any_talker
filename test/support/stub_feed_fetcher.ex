defmodule AnyTalker.RSS.StubFeedFetcher do
  @moduledoc false

  def fetch_and_parse(_url) do
    case Process.get(:stub_feed_fetcher_result) do
      nil -> {:ok, %{title: "Test Feed", entries: []}}
      result -> result
    end
  end
end
