defmodule AnyTalker.RSS.Article do
  @moduledoc """
  Schema for a saved RSS article.

  ## Fields

  | Field Name   | Type              | Description                        |
  |--------------|-------------------|------------------------------------|
  | feed_id      | integer           | Parent feed ID                     |
  | url          | string            | Article URL (unique)               |
  | title        | string            | Article title                      |
  | content      | text              | Full article content               |
  | published_at | utc_datetime_usec | Publication date from the feed     |
  | inserted_at  | utc_datetime_usec | When saved locally                 |
  | updated_at   | utc_datetime_usec | Record update time                 |
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias AnyTalker.RSS.Feed

  schema "rss_articles" do
    field :url, :string
    field :title, :string
    field :content, :string
    field :published_at, :utc_datetime_usec
    field :read?, :boolean, virtual: true

    belongs_to :feed, Feed

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Creates a changeset for an article.

  ## Examples

      iex> changeset(%Article{}, %{url: "https://example.com/post", feed_id: 1})
      %Ecto.Changeset{valid?: true}

  """
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:url, :title, :content, :published_at, :feed_id])
    |> validate_required([:url, :feed_id])
    |> unique_constraint(:url)
  end
end
