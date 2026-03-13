defmodule AnyTalker.RSS.Feed do
  @moduledoc """
  Schema for an RSS feed shared across all users.

  ## Fields

  | Field Name      | Type              | Description                        |
  |-----------------|-------------------|------------------------------------|
  | url             | string            | Feed URL (unique)                  |
  | title           | string            | Feed title (fetched from feed)     |
  | last_fetched_at | utc_datetime_usec | When the feed was last fetched     |
  | last_error      | string            | Error message from last fetch      |
  | last_error_at   | utc_datetime_usec | When the last error occurred       |
  | inserted_at     | utc_datetime_usec | Record creation time               |
  | updated_at      | utc_datetime_usec | Record update time                 |
  """

  use Ecto.Schema

  import Ecto.Changeset

  schema "rss_feeds" do
    field :url, :string
    field :title, :string
    field :last_fetched_at, :utc_datetime_usec
    field :last_error, :string
    field :last_error_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Creates a changeset for a feed.

  ## Examples

      iex> changeset(%Feed{}, %{url: "https://example.com/feed.xml"})
      %Ecto.Changeset{valid?: true}

  """
  def changeset(feed, attrs) do
    feed
    |> cast(attrs, [:url, :title, :last_fetched_at, :last_error, :last_error_at])
    |> validate_required([:url])
    |> unique_constraint(:url)
  end
end
