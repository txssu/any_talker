defmodule JokerCynic.Statistics do
  @moduledoc """
  Context module for aggregating statistics about bot activities.
  """

  import Ecto.Query

  alias JokerCynic.Accounts.User
  alias JokerCynic.Repo

  @doc """
  Gets the top N message authors for a given time range.

  ## Parameters
    * start_date - The start date for the time range (inclusive)
    * end_date - The end date for the time range (inclusive)
    * limit - The maximum number of authors to return (defaults to 3)

  ## Returns
    A list of maps with:
    * from_id - The user ID of the message author
    * message_count - The number of messages sent by the author
    * user - User information if available
  """
  @spec get_top_message_authors(DateTime.t(), DateTime.t(), pos_integer()) :: [map()]
  def get_top_message_authors(start_date, end_date, limit \\ 3) do
    query =
      from m in "messages",
        where: m.sent_date >= ^start_date and m.sent_date <= ^end_date,
        group_by: m.from_id,
        select: %{from_id: m.from_id, message_count: count(m.message_id)},
        order_by: [desc: count(m.message_id)],
        limit: ^limit

    authors = Repo.all(query)

    # Get user information for each author
    Enum.map(authors, fn author ->
      user = Repo.one(from u in User, where: u.id == ^author.from_id, select: u)
      Map.put(author, :user, user)
    end)
  end

  @doc """
  Gets the top N message authors for the current day (UTC).

  ## Parameters
    * limit - The maximum number of authors to return (defaults to 3)

  ## Returns
    A list of maps as per `get_top_message_authors/3`.
  """
  @spec get_top_message_authors_today(pos_integer()) :: [map()]
  def get_top_message_authors_today(limit \\ 3) do
    # Get today's date in UTC at midnight (00:00:00)
    today_start = DateTime.new!(Date.utc_today(), ~T[00:00:00.000], "Etc/UTC")
    # End of the day is just before midnight (23:59:59.999)
    today_end = DateTime.new!(Date.utc_today(), ~T[23:59:59.999], "Etc/UTC")

    get_top_message_authors(today_start, today_end, limit)
  end
end
