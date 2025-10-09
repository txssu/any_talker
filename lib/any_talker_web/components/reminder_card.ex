defmodule AnyTalkerWeb.ReminderCard do
  @moduledoc """
  Reminder card component that displays reminder information.
  """
  use Phoenix.Component

  @doc """
  Renders a reminder card with message, scheduled time, and chat title.

  ## Example

      <.reminder_card
        message="позвонить маме"
        scheduled_at={~U[2025-10-10 15:00:00Z]}
        chat_title="My Chat"
      />
  """
  attr :message, :string, required: true
  attr :scheduled_at, :any, required: true
  attr :chat_title, :string, required: true

  def reminder_card(assigns) do
    ~H"""
    <div class="bg-tg-bg space-y-3 rounded-xl p-4">
      <div class="flex items-start gap-3">
        <div class="min-w-0 flex-1">
          <p class="text-[15px] break-words">{@message}</p>
        </div>
      </div>

      <div class="text-tg-hint flex items-center gap-2 text-sm">
        <span>{format_datetime(@scheduled_at)}</span>
      </div>

      <div class="text-tg-hint flex items-center gap-2 text-sm">
        <span class="truncate">{@chat_title}</span>
      </div>
    </div>
    """
  end

  @doc """
  Renders an admin reminder card with message, scheduled time, chat title, and user name.

  ## Example

      <.admin_reminder_card
        message="позвонить маме"
        scheduled_at={~U[2025-10-10 15:00:00Z]}
        chat_title="My Chat"
        user_name="John Doe"
      />
  """
  attr :message, :string, required: true
  attr :scheduled_at, :any, required: true
  attr :chat_title, :string, required: true
  attr :user_name, :string, required: true

  def admin_reminder_card(assigns) do
    ~H"""
    <div class="bg-tg-bg space-y-3 rounded-xl p-4">
      <div class="flex items-start justify-between gap-3">
        <div class="min-w-0 flex-1">
          <p class="text-[15px] break-words">{@message}</p>
        </div>
        <div class="text-tg-hint flex-shrink-0 text-xs">
          {@user_name}
        </div>
      </div>

      <div class="text-tg-hint flex items-center gap-2 text-sm">
        <span>{format_datetime(@scheduled_at)}</span>
      </div>

      <div class="text-tg-hint flex items-center gap-2 text-sm">
        <span class="truncate">{@chat_title}</span>
      </div>
    </div>
    """
  end

  defp format_datetime(%DateTime{} = datetime) do
    datetime
    |> DateTime.shift_zone!("Asia/Yekaterinburg")
    |> Calendar.strftime("%d.%m.%Y в %H:%M")
  end

  defp format_datetime(%NaiveDateTime{} = naive_datetime) do
    naive_datetime
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!("Asia/Yekaterinburg")
    |> Calendar.strftime("%d.%m.%Y в %H:%M")
  end
end
