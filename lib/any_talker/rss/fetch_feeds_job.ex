defmodule AnyTalker.RSS.FetchFeedsJob do
  @moduledoc """
  Oban cron worker that schedules a `FetchFeedJob` for every active feed.

  Runs every 15 minutes. A feed is active if it has at least one subscription.
  """

  use Oban.Worker, queue: :rss

  import Ecto.Query

  alias AnyTalker.Repo
  alias AnyTalker.RSS.Feed
  alias AnyTalker.RSS.FetchFeedJob
  alias AnyTalker.RSS.Subscription

  @impl Oban.Worker
  def perform(_job) do
    query =
      from f in Feed,
        join: s in Subscription,
        on: s.feed_id == f.id,
        select: f.id,
        distinct: true

    active_feed_ids = Repo.all(query)

    Enum.each(active_feed_ids, fn feed_id ->
      %{"feed_id" => feed_id}
      |> FetchFeedJob.new()
      |> Oban.insert()
    end)

    :ok
  end
end
