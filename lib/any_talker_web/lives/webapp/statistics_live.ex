defmodule AnyTalkerWeb.WebApp.StatisticsLive do
  @moduledoc false
  use AnyTalkerWeb, :live_view

  import AnyTalker.LocalizationUtils, only: [pluralize: 4]
  import AnyTalkerWeb.TelegramComponents

  alias AnyTalker.Accounts
  alias AnyTalker.Settings
  alias AnyTalker.Statistics

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="back-init" phx-hook="TelegramBack" data-state="on"></div>
    <div class="space-y-5">
      <.section class="pt-[30px] pb-[15px]">
        <div class="flex justify-center">
          <img src={~p"/avatar/#{@chat_config.id}"} class="rounded-full" width="90" height="90" alt="Chat photo" />
        </div>
        <h1 class="mt-[15px] text-center text-xl font-bold">{@chat_config.title}</h1>
        <p class="text-tg-hint text-center text-sm">Статистика сообщений</p>
      </.section>

      <.section>
        <:header>Выбор даты</:header>
        <div class="mt-2 flex items-center justify-center gap-2">
          <button
            phx-click="prev_day"
            class="hover-effect rounded-lg p-2"
            aria-label="Предыдущий день"
          >
            ←
          </button>
          <input
            type="date"
            value={Date.to_iso8601(@selected_date)}
            max={Date.to_iso8601(@today)}
            phx-change="select_date"
            name="date"
            class="rounded-lg border-none bg-transparent text-center text-lg font-medium"
          />
          <button
            phx-click="next_day"
            disabled={@selected_date == @today}
            class="hover-effect rounded-lg p-2 disabled:opacity-30"
            aria-label="Следующий день"
          >
            →
          </button>
        </div>
        <div class="mt-2 flex justify-center gap-2">
          <button
            :if={@selected_date != @today}
            phx-click="go_today"
            class="hover-effect rounded-lg px-3 py-1 text-sm text-blue-500"
          >
            Сегодня
          </button>
        </div>
      </.section>

      <.section>
        <:header>Топ 5 отправителей за {format_date(@selected_date, @today)}</:header>
        <p :if={@top_authors == []} class="text-[15px] text-tg-hint mt-2.5 text-center">
          Нет сообщений за этот день
        </p>
        <ul :if={@top_authors != []}>
          <li :for={{author, position} <- Enum.with_index(@top_authors, 1)}>
            <a
              href={"https://t.me/#{author.user.username}"}
              class="border-tg-section-separator hover-effect h-[42px] flex items-center rounded-lg border-b-2 pl-5 last:border-b-0"
            >
              <span class="text-tg-hint text-[15px] w-8 font-bold">{position}</span>
              <span class="text-[15px] flex-1 py-2.5">
                {username(author.user)} — {author.message_count} {message_word(author.message_count)}
              </span>
            </a>
          </li>
        </ul>
      </.section>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"chat_id" => chat_id}, _session, socket) do
    chat_config = Settings.get_chat_config(chat_id)
    today = Date.utc_today()
    top_authors = Statistics.get_top_message_authors_for_date(today, chat_id, 5)

    {:ok,
     assign(socket,
       chat_config: chat_config,
       chat_id: chat_id,
       selected_date: today,
       today: today,
       top_authors: top_authors
     )}
  end

  @impl Phoenix.LiveView
  def handle_event("select_date", %{"date" => date_string}, socket) do
    case Date.from_iso8601(date_string) do
      {:ok, date} ->
        {:noreply, load_stats_for_date(socket, date)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("prev_day", _params, socket) do
    new_date = Date.add(socket.assigns.selected_date, -1)
    {:noreply, load_stats_for_date(socket, new_date)}
  end

  @impl Phoenix.LiveView
  def handle_event("next_day", _params, socket) do
    new_date = Date.add(socket.assigns.selected_date, 1)

    if Date.after?(new_date, socket.assigns.today) do
      {:noreply, socket}
    else
      {:noreply, load_stats_for_date(socket, new_date)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("go_today", _params, socket) do
    {:noreply, load_stats_for_date(socket, socket.assigns.today)}
  end

  defp load_stats_for_date(socket, date) do
    top_authors = Statistics.get_top_message_authors_for_date(date, socket.assigns.chat_id, 5)
    assign(socket, selected_date: date, top_authors: top_authors)
  end

  defp username(nil), do: "Неизвестный пользователь"
  defp username(user), do: Accounts.display_name(user) || user.username

  defp message_word(count), do: pluralize(count, "сообщение", "сообщения", "сообщений")

  defp format_date(date, today) do
    cond do
      date == today -> "сегодня"
      date == Date.add(today, -1) -> "вчера"
      true -> Calendar.strftime(date, "%d.%m.%Y")
    end
  end
end
