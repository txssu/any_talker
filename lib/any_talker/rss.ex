defmodule AnyTalker.RSS do
  @moduledoc """
  Context for managing RSS feeds, groups, subscriptions, and read state.
  """

  import Ecto.Query

  alias AnyTalker.Repo
  alias AnyTalker.RSS.Article
  alias AnyTalker.RSS.Feed
  alias AnyTalker.RSS.Group
  alias AnyTalker.RSS.ReadStatus
  alias AnyTalker.RSS.Subscription
  alias Ecto.Multi

  # ── Groups ──────────────────────────────────────────────────────────────────

  @doc """
  Creates a named group for a user.

  ## Examples

      iex> create_group(user_id, "Tech")
      {:ok, %Group{}}

  """
  def create_group(user_id, name) do
    %Group{}
    |> Group.changeset(%{user_id: user_id, name: name})
    |> Repo.insert()
  end

  @doc """
  Deletes a group. Returns error if the group does not belong to the user.
  Subscriptions are cascade-deleted by the database.

  ## Examples

      iex> delete_group(user_id, group_id)
      :ok

  """
  def delete_group(user_id, group_id) do
    case Repo.get_by(Group, id: group_id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      group ->
        case Repo.delete(group) do
          {:ok, _deleted} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @doc """
  Returns the user's "Default" group, creating it if it does not exist.

  ## Examples

      iex> get_or_create_default_group(user_id)
      {:ok, %Group{name: "Default"}}

  """
  def get_or_create_default_group(user_id) do
    case Repo.get_by(Group, user_id: user_id, name: "Default") do
      nil -> create_group(user_id, "Default")
      group -> {:ok, group}
    end
  end

  @doc """
  Lists all groups for a user with their unread article counts.

  Returns a list of `{%Group{}, unread_count}` tuples ordered by group name.

  ## Examples

      iex> list_groups(user_id)
      [{%Group{name: "Tech"}, 3}, {%Group{name: "News"}, 0}]

  """
  def list_groups(user_id) do
    query = from g in Group, where: g.user_id == ^user_id, order_by: g.name

    query
    |> Repo.all()
    |> Enum.map(fn group -> {group, unread_count(user_id, group.id)} end)
  end

  defp unread_cutoff, do: DateTime.add(DateTime.utc_now(), -48, :hour)

  defp unread_count(user_id, group_id) do
    cutoff = unread_cutoff()

    query =
      from a in Article,
        join: s in Subscription,
        on: s.feed_id == a.feed_id and s.user_id == ^user_id and s.group_id == ^group_id,
        left_join: rs in ReadStatus,
        on: rs.article_id == a.id and rs.user_id == ^user_id,
        where: is_nil(rs.id) and a.inserted_at > ^cutoff

    Repo.aggregate(query, :count, :id)
  end

  # ── Subscriptions ────────────────────────────────────────────────────────────

  @doc """
  Subscribes a user to a feed in the given group.

  - Creates the feed record if it does not exist yet.
  - Marks all articles already in the feed as read at subscription creation time.
  - Returns `{:error, :group_not_found}` if the group does not belong to the user.
  - Returns `{:error, :already_subscribed}` if already subscribed.

  ## Examples

      iex> subscribe(user_id, "https://example.com/feed.xml", group_id)
      {:ok, %Subscription{}}

  """
  def subscribe(user_id, feed_url, group_id) do
    with {:ok, fetch_result} <- maybe_fetch_new_feed(feed_url) do
      Multi.new()
      |> Multi.run(:group, fn repo, _changes -> fetch_group(repo, group_id, user_id) end)
      |> Multi.run(:feed, fn repo, _changes -> get_or_create_feed(repo, feed_url, fetch_result) end)
      |> Multi.run(:save_articles, fn repo, %{feed: feed} ->
        save_fetched_articles(repo, feed, fetch_result)
      end)
      |> Multi.run(:subscription, fn repo, %{feed: feed} ->
        insert_subscription(repo, user_id, feed.id, group_id)
      end)
      |> Multi.run(:mark_existing_read, fn repo, %{feed: feed, subscription: sub} ->
        mark_existing_articles_read(repo, user_id, feed.id, sub.inserted_at)
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{subscription: sub}} -> {:ok, sub}
        {:error, _step, reason, _changes} -> {:error, reason}
      end
    end
  end

  defp fetch_group(repo, group_id, user_id) do
    case repo.get_by(Group, id: group_id, user_id: user_id) do
      nil -> {:error, :group_not_found}
      group -> {:ok, group}
    end
  end

  defp maybe_fetch_new_feed(url) do
    case Repo.get_by(Feed, url: url) do
      nil ->
        fetcher = Application.get_env(:any_talker, :feed_fetcher, AnyTalker.RSS.FeedFetcher)

        case fetcher.fetch_and_parse(url) do
          {:ok, result} -> {:ok, result}
          {:error, _reason} -> {:error, :fetch_failed}
        end

      _feed ->
        {:ok, nil}
    end
  end

  defp get_or_create_feed(repo, feed_url, %{title: title}) do
    repo.insert(%Feed{url: feed_url, title: title})
  end

  defp get_or_create_feed(repo, feed_url, nil) do
    case repo.get_by(Feed, url: feed_url) do
      nil -> repo.insert(%Feed{url: feed_url})
      feed -> {:ok, feed}
    end
  end

  defp save_fetched_articles(_repo, _feed, nil), do: {:ok, 0}

  defp save_fetched_articles(repo, feed, %{entries: entries}) do
    now = DateTime.utc_now()

    rows =
      Enum.map(entries, fn entry ->
        entry
        |> Map.put_new(:guid, entry.url)
        |> Map.merge(%{feed_id: feed.id, inserted_at: now, updated_at: now})
      end)

    repo.insert_all(Article, rows,
      on_conflict: {:replace, [:url, :title, :updated_at]},
      conflict_target: :guid
    )
    {:ok, length(rows)}
  end

  defp insert_subscription(repo, user_id, feed_id, group_id) do
    %Subscription{}
    |> Subscription.changeset(%{user_id: user_id, feed_id: feed_id, group_id: group_id})
    |> repo.insert()
    |> normalize_subscription_error()
  end

  defp normalize_subscription_error({:error, %{errors: errors} = changeset}) do
    if Keyword.has_key?(errors, :feed_id) do
      {:error, :already_subscribed}
    else
      {:error, changeset}
    end
  end

  defp normalize_subscription_error(ok), do: ok

  defp mark_existing_articles_read(repo, user_id, feed_id, cutoff) do
    now = DateTime.utc_now()

    article_ids_query =
      from a in Article,
        where: a.feed_id == ^feed_id and a.inserted_at <= ^cutoff,
        select: a.id

    read_statuses =
      article_ids_query
      |> repo.all()
      |> Enum.map(fn id ->
        %{user_id: user_id, article_id: id, inserted_at: now, updated_at: now}
      end)

    repo.insert_all(ReadStatus, read_statuses, on_conflict: :nothing)
    {:ok, length(read_statuses)}
  end

  @doc """
  Removes all subscriptions for the given feed URL across all groups for a user.

  ## Examples

      iex> unsubscribe(user_id, "https://example.com/feed.xml")
      :ok

  """
  def unsubscribe(user_id, feed_url) do
    feed = Repo.get_by(Feed, url: feed_url)

    if feed do
      query = from s in Subscription, where: s.user_id == ^user_id and s.feed_id == ^feed.id
      Repo.delete_all(query)
    end

    :ok
  end

  @doc """
  Lists all feeds subscribed to in a group.

  ## Examples

      iex> list_feeds(user_id, group_id)
      [%Feed{}]

  """
  def list_feeds(user_id, group_id) do
    query =
      from f in Feed,
        join: s in Subscription,
        on: s.feed_id == f.id and s.user_id == ^user_id and s.group_id == ^group_id,
        order_by: f.url

    Repo.all(query)
  end

  @doc """
  Lists articles from feeds the user is subscribed to, with pagination and read status.

  Returns `{articles, total_count}` where each article has `read?` populated.
  Articles are ordered newest first. `group_id_or_nil` filters by group; `nil` means all groups.

  ## Examples

      iex> list_articles(user_id, nil, 0)
      {[%Article{read?: false}, ...], 42}

  """
  def list_articles(user_id, group_id_or_nil, page, page_size \\ 15) do
    cutoff = unread_cutoff()
    offset = page * page_size

    subscription_exists = subscription_exists_query(user_id, group_id_or_nil)

    base_query =
      from a in Article,
        as: :article,
        where: exists(subscription_exists)

    total = Repo.aggregate(base_query, :count, :id)

    page_query =
      from([a] in base_query,
        left_join: rs in ReadStatus,
        on: rs.article_id == a.id and rs.user_id == ^user_id,
        select_merge: %{read?: not is_nil(rs.id) or a.inserted_at < ^cutoff},
        order_by: [desc_nulls_last: a.published_at, desc: a.inserted_at],
        limit: ^page_size,
        offset: ^offset
      )

    {Repo.all(page_query), total}
  end

  # ── News / Read state ────────────────────────────────────────────────────────

  @doc """
  Lists unread articles for a user in a specific group, ordered by published_at descending.

  ## Examples

      iex> list_unread(user_id, group_id)
      [%Article{}, ...]

  """
  def list_unread(user_id, group_id) do
    cutoff = unread_cutoff()

    query =
      from a in Article,
        join: s in Subscription,
        on: s.feed_id == a.feed_id and s.user_id == ^user_id and s.group_id == ^group_id,
        left_join: rs in ReadStatus,
        on: rs.article_id == a.id and rs.user_id == ^user_id,
        where: is_nil(rs.id) and a.inserted_at > ^cutoff,
        order_by: [desc: a.published_at]

    Repo.all(query)
  end

  @doc """
  Lists unread articles for a user across all groups, ordered by published_at descending.

  ## Examples

      iex> list_unread_all(user_id)
      [%Article{}, ...]

  """
  def list_unread_all(user_id) do
    cutoff = unread_cutoff()

    query =
      from a in Article,
        join: s in Subscription,
        on: s.feed_id == a.feed_id and s.user_id == ^user_id,
        left_join: rs in ReadStatus,
        on: rs.article_id == a.id and rs.user_id == ^user_id,
        where: is_nil(rs.id) and a.inserted_at > ^cutoff,
        order_by: [desc: a.published_at],
        distinct: true

    Repo.all(query)
  end

  @doc """
  Marks the given article IDs as read for a user. Idempotent.

  ## Examples

      iex> mark_read(user_id, [1, 2, 3])
      :ok

  """
  def mark_read(user_id, article_ids) when is_list(article_ids) do
    now = DateTime.utc_now()

    entries =
      Enum.map(article_ids, fn id ->
        %{user_id: user_id, article_id: id, inserted_at: now, updated_at: now}
      end)

    Repo.insert_all(ReadStatus, entries, on_conflict: :nothing)
    :ok
  end

  @doc """
  Marks all currently unread articles as read for a user. Idempotent.

  Only marks articles newer than 48 hours (older articles are already treated as read via query-level cutoff).
  `group_id_or_nil` filters by group; `nil` marks across all groups.

  ## Examples

      iex> mark_all_read(user_id, nil)
      :ok

  """
  def mark_all_read(user_id, group_id_or_nil) do
    cutoff = unread_cutoff()
    now = DateTime.utc_now()

    subscription_exists = subscription_exists_query(user_id, group_id_or_nil)

    unread_query =
      from a in Article,
        as: :article,
        where: exists(subscription_exists) and a.inserted_at > ^cutoff,
        left_join: rs in ReadStatus,
        on: rs.article_id == a.id and rs.user_id == ^user_id,
        where: is_nil(rs.id),
        select: a.id

    article_ids = Repo.all(unread_query)
    entries = Enum.map(article_ids, &%{user_id: user_id, article_id: &1, inserted_at: now, updated_at: now})
    Repo.insert_all(ReadStatus, entries, on_conflict: :nothing)
    :ok
  end

  defp subscription_exists_query(user_id, nil) do
    from s in Subscription,
      where: s.feed_id == parent_as(:article).feed_id and s.user_id == ^user_id
  end

  defp subscription_exists_query(user_id, group_id) do
    from s in Subscription,
      where:
        s.feed_id == parent_as(:article).feed_id and
          s.user_id == ^user_id and
          s.group_id == ^group_id
  end

  @doc """
  Finds a group by user and name. Returns `nil` if not found.

  ## Examples

      iex> get_group_by_name(user_id, "Tech")
      %Group{}

  """
  def get_group_by_name(user_id, name) do
    Repo.get_by(Group, user_id: user_id, name: name)
  end
end
