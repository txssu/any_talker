defmodule AnyTalkerWeb.WebApp.AllRemindersLive do
  @moduledoc false
  use AnyTalkerWeb, :live_view

  import AnyTalkerWeb.ReminderCard
  import AnyTalkerWeb.TelegramComponents

  alias AnyTalker.Reminders

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="back-init" phx-hook="TelegramBack" data-state="on"></div>
    <.section class="pt-[30px] pb-[15px]">
      <h1 class="mt-[15px] text-center text-xl font-bold">Все напоминания</h1>
    </.section>

    <.section :if={@reminders == []} class="mt-5">
      <p class="text-tg-hint text-[15px] text-center">Нет запланированных напоминаний</p>
    </.section>

    <div :if={@reminders != []} class="mt-5 space-y-3">
      <.admin_reminder_card
        :for={reminder <- @reminders}
        message={reminder.message}
        scheduled_at={reminder.scheduled_at}
        chat_title={reminder.chat_title}
        user_name={reminder.user_name}
      />
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    reminders = Reminders.list_all_reminders()
    {:ok, assign(socket, reminders: reminders)}
  end

  @impl Phoenix.LiveView
  def handle_event("back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/webapp")}
  end
end
