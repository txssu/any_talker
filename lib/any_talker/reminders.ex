defmodule AnyTalker.Reminders do
  @moduledoc """
  Context for managing user reminders.
  """
  import Ecto.Query

  alias AnyTalker.Accounts.User
  alias AnyTalker.Repo
  alias AnyTalker.Settings.ChatConfig

  @doc """
  Lists all scheduled reminders for a user.

  Returns a list of reminders with their details.

  ## Examples

      iex> list_user_reminders(123)
      [
        %{
          id: 1,
          message: "позвонить маме",
          scheduled_at: ~U[2025-10-10 15:00:00Z],
          chat_id: 456,
          chat_title: "My Chat"
        }
      ]
  """
  def list_user_reminders(user_id) do
    query =
      from j in "oban_jobs",
        where: j.worker == "AnyTalker.AI.SendReminderJob",
        where: j.state in ["scheduled", "available", "retryable"],
        where: fragment("(?->>'user_id')::bigint = ?", j.args, ^user_id),
        select: %{
          id: j.id,
          message: fragment("?->>'message'", j.args),
          scheduled_at: j.scheduled_at,
          chat_id: fragment("(?->>'chat_id')::bigint", j.args)
        },
        order_by: [asc: j.scheduled_at]

    reminders = Repo.all(query)

    chat_ids =
      reminders
      |> Enum.map(& &1.chat_id)
      |> Enum.uniq()

    chat_titles =
      from(c in ChatConfig,
        where: c.id in ^chat_ids,
        select: {c.id, c.title}
      )
      |> Repo.all()
      |> Map.new()

    Enum.map(reminders, fn reminder ->
      Map.put(reminder, :chat_title, Map.get(chat_titles, reminder.chat_id, "Неизвестный чат"))
    end)
  end

  @doc """
  Lists all scheduled reminders in the system (admin only).

  Returns a list of reminders with their details including user information.

  ## Examples

      iex> list_all_reminders()
      [
        %{
          id: 1,
          message: "позвонить маме",
          scheduled_at: ~U[2025-10-10 15:00:00Z],
          chat_id: 456,
          chat_title: "My Chat",
          user_id: 123,
          user_name: "John Doe"
        }
      ]
  """
  def list_all_reminders do
    query =
      from j in "oban_jobs",
        where: j.worker == "AnyTalker.AI.SendReminderJob",
        where: j.state in ["scheduled", "available", "retryable"],
        select: %{
          id: j.id,
          message: fragment("?->>'message'", j.args),
          scheduled_at: j.scheduled_at,
          chat_id: fragment("(?->>'chat_id')::bigint", j.args),
          user_id: fragment("(?->>'user_id')::bigint", j.args)
        },
        order_by: [asc: j.scheduled_at]

    reminders = Repo.all(query)

    chat_ids =
      reminders
      |> Enum.map(& &1.chat_id)
      |> Enum.uniq()

    user_ids =
      reminders
      |> Enum.map(& &1.user_id)
      |> Enum.uniq()

    chat_titles =
      from(c in ChatConfig,
        where: c.id in ^chat_ids,
        select: {c.id, c.title}
      )
      |> Repo.all()
      |> Map.new()

    users =
      from(u in User,
        where: u.id in ^user_ids,
        select: {u.id, u}
      )
      |> Repo.all()
      |> Map.new()

    Enum.map(reminders, fn reminder ->
      user = Map.get(users, reminder.user_id)
      user_name = if user, do: user.custom_name || user.first_name, else: "Неизвестный"

      reminder
      |> Map.put(:chat_title, Map.get(chat_titles, reminder.chat_id, "Неизвестный чат"))
      |> Map.put(:user_name, user_name)
    end)
  end
end
