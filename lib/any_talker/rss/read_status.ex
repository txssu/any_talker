defmodule AnyTalker.RSS.ReadStatus do
  @moduledoc """
  Schema tracking which articles a user has read.

  ## Fields

  | Field Name  | Type              | Description                         |
  |-------------|-------------------|-------------------------------------|
  | user_id     | integer           | User who read the article           |
  | article_id  | integer           | Article that was read               |
  | inserted_at | utc_datetime_usec | When the article was marked read    |
  | updated_at  | utc_datetime_usec | Record update time                  |
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias AnyTalker.Accounts.User
  alias AnyTalker.RSS.Article

  schema "rss_read_statuses" do
    belongs_to :user, User
    belongs_to :article, Article

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Creates a changeset for a read status.

  ## Examples

      iex> changeset(%ReadStatus{}, %{user_id: 1, article_id: 5})
      %Ecto.Changeset{valid?: true}

  """
  def changeset(read_status, attrs) do
    read_status
    |> cast(attrs, [:user_id, :article_id])
    |> validate_required([:user_id, :article_id])
    |> unique_constraint(:article_id, name: :rss_read_statuses_user_id_article_id_index)
  end
end
