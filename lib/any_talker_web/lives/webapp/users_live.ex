defmodule AnyTalkerWeb.WebApp.UsersLive do
  @moduledoc false
  use AnyTalkerWeb, :live_view

  import AnyTalkerWeb.TelegramComponents

  alias AnyTalker.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="back-init" phx-hook="TelegramBack" data-state="on"></div>
    <.section class="pt-[30px] pb-[15px]">
      <h1 class="mt-[15px] text-center text-xl font-bold">Пользователи</h1>
    </.section>

    <.section class="mt-5">
      <:header>Пользователи</:header>
      <ul>
        <li :for={user <- @users}>
          <.link
            navigate={~p"/webapp/profile/#{user.id}"}
            class="mb-2 flex items-center justify-between rounded-lg px-4 py-2 hover:bg-tg-section-hover"
          >
            <span class="font-semibold">{user.username || user.id}</span>
          </.link>
        </li>
      </ul>
    </.section>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    users = Accounts.list_users()

    {:ok, assign(socket, users: users)}
  end

  @impl Phoenix.LiveView
  def handle_event("back", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/webapp")}
  end
end
