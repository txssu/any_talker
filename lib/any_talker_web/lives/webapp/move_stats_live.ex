defmodule AnyTalkerWeb.WebApp.MoveStatsLive do
  @moduledoc false
  use AnyTalkerWeb, :live_view

  import AnyTalkerWeb.TelegramComponents

  alias AnyTalker.Events
  alias AnyTalker.Settings

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
        <p class="text-tg-hint text-center text-sm">Статистика /move</p>
      </.section>

      <.section>
        <:header>Топ участников</:header>
        <p :if={@move_stats == []} class="text-[15px] text-tg-hint mt-2.5 text-center">
          Нет данных
        </p>
        <ul :if={@move_stats != []}>
          <li :for={{stat, position} <- Enum.with_index(@move_stats, 1)}>
            <.link
              navigate={~p"/webapp/profile/#{stat.user.id}"}
              class="border-tg-section-separator hover-effect flex items-center gap-3 rounded-lg border-b-2 px-3 py-2 last:border-b-0"
            >
              <div class="text-tg-hint text-[17px] w-8 flex-shrink-0 text-center font-bold">
                {position}
              </div>
              <img
                src={stat.user.photo_url || ~p"/user_avatar/#{stat.user.id}"}
                class="size-10 flex-shrink-0 rounded-full"
                alt="User photo"
              />
              <div class="flex min-w-0 flex-1 flex-col">
                <span class="text-[15px] truncate font-medium">
                  {stat.user.first_name} {stat.user.last_name}
                </span>
                <span :if={stat.user.username} class="text-tg-hint text-[13px] truncate">
                  @{stat.user.username}
                </span>
              </div>
              <div class="flex flex-shrink-0 flex-col items-end">
                <span class="text-[20px] font-bold">{stat.forwards}</span>
                <span class="text-tg-hint text-[11px]">
                  {stat.left} ← → {stat.right}
                </span>
              </div>
            </.link>
          </li>
        </ul>
      </.section>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(%{"chat_id" => chat_id}, _session, socket) do
    chat_config = Settings.get_chat_config(chat_id)
    move_stats = Events.list_move_stats_for_chat(chat_id)

    {:ok,
     assign(socket,
       chat_config: chat_config,
       chat_id: chat_id,
       move_stats: move_stats
     )}
  end
end
