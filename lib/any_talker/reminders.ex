defmodule AnyTalker.Reminders do
  @moduledoc """
  Context for managing user reminders.
  """
  import Ecto.Query

  alias AnyTalker.AI.SendReminderJob
  alias AnyTalker.Reminders.Reminder
  alias AnyTalker.Repo
  alias Ecto.Multi

  @doc """
  Gets a single reminder.

  Raises `Ecto.NoResultsError` if the Reminder does not exist.

  ## Examples

      iex> get_reminder!(123)
      %Reminder{}

      iex> get_reminder!(456)
      ** (Ecto.NoResultsError)
  """
  def get_reminder!(id), do: Repo.get!(Reminder, id)

  @doc """
  Creates a reminder and schedules an Oban job in a transaction.

  ## Examples

      iex> create_reminder(%{message: "Test", chat_id: 123, user_id: 456, scheduled_at: ~U[2025-01-01 12:00:00.000000Z]})
      {:ok, %Reminder{}}

      iex> create_reminder(%{message: nil})
      {:error, %Ecto.Changeset{}}
  """
  def create_reminder(attrs) do
    Multi.new()
    |> Multi.insert(:reminder, Reminder.changeset(%Reminder{}, attrs))
    |> Multi.run(:job, fn _repo, %{reminder: reminder} ->
      %{"reminder_id" => reminder.id}
      |> SendReminderJob.new(scheduled_at: reminder.scheduled_at)
      |> Oban.insert()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{reminder: reminder}} -> {:ok, reminder}
      {:error, :reminder, changeset, _changes} -> {:error, changeset}
      {:error, :job, reason, _changes} -> {:error, reason}
    end
  end

  @doc """
  Lists all scheduled reminders for a user.

  Returns a list of Reminder structs with preloaded associations.

  ## Examples

      iex> list_user_reminders(123)
      [%Reminder{id: 1, message: "позвонить маме", ...}]
  """
  def list_user_reminders(user_id) do
    query =
      from r in Reminder,
        where: r.user_id == ^user_id,
        where: r.scheduled_at > ^DateTime.utc_now(),
        order_by: [asc: r.scheduled_at],
        preload: [:chat_config]

    Repo.all(query)
  end

  @doc """
  Lists all scheduled reminders in the system (admin only).

  Returns a list of Reminder structs with preloaded associations.

  ## Examples

      iex> list_reminders()
      [%Reminder{id: 1, message: "позвонить маме", ...}]
  """
  def list_reminders do
    query =
      from r in Reminder,
        where: r.scheduled_at > ^DateTime.utc_now(),
        order_by: [asc: r.scheduled_at],
        preload: [:user, :chat_config]

    Repo.all(query)
  end
end
