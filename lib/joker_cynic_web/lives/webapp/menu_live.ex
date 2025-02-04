defmodule JokerCynicWeb.WebApp.MenuLive do
  @moduledoc false
  use JokerCynicWeb, :live_view

  import JokerCynicWeb.TelegramComponents

  alias JokerCynic.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="back-init" phx-hook="TelegramBack" data-state="off"></div>
    <.section class="pt-[30px] pb-[15px]">
      <div class="flex justify-center">
        <img src={@current_user.photo_url} class="rounded-full" width="90" height="90" alt="User photo" />
      </div>
      <h1 class="mt-[15px] text-center text-xl font-bold">Добро пожаловать, {@current_user.first_name}!</h1>
      <p class="text-tg-hint mt-2.5 text-center text-sm">Циничны как никогда</p>
    </.section>

    <.section class="mt-5">
      <:header>Чаты</:header>
      <p :if={@chats == []} class="text-[15px] text-tg-hint mt-2.5 text-center">Как одинокий зритель в пустом зале</p>
      <ul>
        <li
          :for={chat <- @chats}
          class="border-tg-section-separator hover-effect h-[42px] flex items-center rounded-lg border-b-2 pl-5 last:border-b-0"
        >
          <.link navigate={~p"/webapp/c/#{chat.id}"}>
            <span class="text-[15px] py-2.5">{chat.title}</span>
          </.link>
        </li>
      </ul>
    </.section>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    chats = Accounts.list_user_chats(socket.assigns.current_user.id)
    {:ok, assign(socket, chats: chats)}
  end
end
