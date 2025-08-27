defmodule AnyTalker.Statistics do
  @moduledoc """
  Context module for aggregating statistics about bot activities.
  """

  import Ecto.Query

  alias AnyTalker.Accounts.User
  alias AnyTalker.Events.Message
  alias AnyTalker.Repo

  @doc """
  Gets the top N message authors for a given time range.

  ## Parameters
    * start_date — inclusive start of the time range
    * end_date — inclusive end of the time range
    * chat_id — ID of the chat to filter messages by
    * limit — maximum number of authors to return (defaults to 3)

  ## Returns
  A list of maps with keys:
    * :from_id — user ID of the author
    * :message_count — number of messages they’ve sent
    * :user — the `%AnyTalker.Accounts.User{}` struct for that author
  """
  def get_top_message_authors(start_date, end_date, chat_id, limit \\ 3) do
    query =
      from m in Message,
        join: u in User,
        on: u.id == m.from_id,
        where:
          m.sent_date >= ^start_date and
            m.sent_date <= ^end_date and
            m.chat_id == ^chat_id,
        group_by: [u.id, m.from_id],
        select: %{
          from_id: m.from_id,
          message_count: count(m.from_id),
          user: u
        },
        order_by: [desc: count(m.from_id)],
        limit: ^limit

    Repo.all(query)
  end

  @doc """
  Gets the top N message authors for the current day (UTC).

  ## Parameters
    * limit - The maximum number of authors to return (defaults to 3)

  ## Returns
    A list of maps as per `get_top_message_authors/3`.
  """
  def get_top_message_authors_today(chat_id, limit \\ 3) do
    # Get today's date in UTC at midnight (00:00:00)
    today_start = DateTime.new!(Date.utc_today(), ~T[00:00:00.000], "Etc/UTC")
    # End of the day is just before midnight (23:59:59.999)
    today_end = DateTime.new!(Date.utc_today(), ~T[23:59:59.999], "Etc/UTC")

    get_top_message_authors(today_start, today_end, chat_id, limit)
  end
end
