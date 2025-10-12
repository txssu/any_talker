defmodule AnyTalker.Reminders.Reminder do
  @moduledoc """
  Schema for storing reminder information.

  ## Fields

  | Field Name   | Type                | Description                                    |
  |--------------|---------------------|------------------------------------------------|
  | message      | string              | The reminder message text                      |
  | chat_id      | integer             | Telegram chat ID where reminder will be sent   |
  | user_id      | integer             | Telegram user ID who created the reminder      |
  | reply_to_id  | integer             | Telegram message ID to reply to (optional)     |
  | scheduled_at | DateTime            | When the reminder should be sent               |
  | user         | User                | Associated user (preloaded)                    |
  | chat_config  | ChatConfig          | Associated chat config (preloaded)             |
  | inserted_at  | DateTime            | When the reminder was created                  |
  | updated_at   | DateTime            | When the reminder was last updated             |
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias AnyTalker.Accounts.User
  alias AnyTalker.Settings.ChatConfig

  schema "reminders" do
    field :message, :string
    field :reply_to_id, :integer
    field :scheduled_at, :utc_datetime_usec

    belongs_to :user, User
    belongs_to :chat_config, ChatConfig, foreign_key: :chat_id

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Creates a changeset for a reminder.

  ## Examples

      iex> changeset(%Reminder{}, %{message: "Test", chat_id: 123, user_id: 456, scheduled_at: ~U[2025-01-01 12:00:00.000000Z]})
      %Ecto.Changeset{valid?: true}

  """
  def changeset(reminder, attrs) do
    reminder
    |> cast(attrs, [:message, :user_id, :chat_id, :reply_to_id, :scheduled_at])
    |> validate_required([:message, :user_id, :chat_id, :scheduled_at])
  end
end
