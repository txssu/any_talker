defmodule AnyTalker.RSS.FetchFeedJob do
  @moduledoc """
  Oban worker that fetches a single RSS feed and saves new articles.

  Expected args: `%{"feed_id" => integer}`
  """

  use Oban.Worker, queue: :rss

  alias AnyTalker.Repo
  alias AnyTalker.RSS
  alias AnyTalker.RSS.Feed
  alias AnyTalker.RSS.FeedFetcher

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"feed_id" => feed_id}}) do
    feed = Repo.get!(Feed, feed_id)

    case FeedFetcher.fetch_and_parse(feed.url) do
      {:ok, %{title: title, entries: entries}} ->
        save_articles(feed, entries)
        update_feed(feed, title)
        :ok

      {:error, reason} ->
        Logger.warning("FetchFeedJob failed for feed #{feed_id}: #{inspect(reason)}")
        set_feed_error(feed, reason)
        {:error, reason}
    end
  end

  defp save_articles(feed, entries) do
    now = DateTime.utc_now()

    rows =
      Enum.map(entries, fn entry ->
        %{
          feed_id: feed.id,
          url: entry.url,
          guid: entry.guid,
          title: entry.title,
          content: entry.content,
          published_at: entry.published_at,
          inserted_at: now,
          updated_at: now
        }
      end)

    RSS.upsert_articles(rows)
  end

  defp update_feed(feed, title) do
    feed
    |> Feed.changeset(%{
      title: title || feed.title,
      last_fetched_at: DateTime.utc_now(),
      last_error: nil,
      last_error_at: nil
    })
    |> Repo.update()
  end

  defp set_feed_error(feed, reason) do
    feed
    |> Feed.changeset(%{
      last_error: inspect(reason),
      last_error_at: DateTime.utc_now()
    })
    |> Repo.update()
  end
end
