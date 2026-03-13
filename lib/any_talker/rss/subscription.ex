defmodule AnyTalker.RSS.Subscription do
  @moduledoc """
  Schema linking a user to a feed within a group.

  ## Fields

  | Field Name  | Type              | Description                         |
  |-------------|-------------------|-------------------------------------|
  | user_id     | integer           | Subscribing user ID                 |
  | feed_id     | integer           | Subscribed feed ID                  |
  | group_id    | integer           | Group this subscription belongs to  |
  | inserted_at | utc_datetime_usec | Record creation time                |
  | updated_at  | utc_datetime_usec | Record update time                  |
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias AnyTalker.Accounts.User
  alias AnyTalker.RSS.Feed
  alias AnyTalker.RSS.Group

  schema "rss_subscriptions" do
    belongs_to :user, User
    belongs_to :feed, Feed
    belongs_to :group, Group

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Creates a changeset for a subscription.

  ## Examples

      iex> changeset(%Subscription{}, %{user_id: 1, feed_id: 2, group_id: 3})
      %Ecto.Changeset{valid?: true}

  """
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:user_id, :feed_id, :group_id])
    |> validate_required([:user_id, :feed_id, :group_id])
    |> unique_constraint(:feed_id, name: :rss_subscriptions_user_id_feed_id_group_id_index)
  end
end
