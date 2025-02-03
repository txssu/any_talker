defmodule JokerCynicWeb.WebApp.MenuLive do
  @moduledoc false
  use JokerCynicWeb, :live_view

  alias JokerCynic.Accounts

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section class="bg-tg-bg pt-[30px] pb-[15px] rounded-xl">
      <div class="flex justify-center">
        <img src={@current_user.photo_url} class="rounded-full" width="90" height="90" alt="User photo" />
      </div>
      <h1 class="mt-[15px] text-center text-xl font-bold">Добро пожаловать, {@current_user.first_name}!</h1>
      <p class="text-tg-hint mt-2.5 text-center text-sm">Циничен как никогда</p>
    </section>

    <section class="bg-tg-bg p-[15px] mt-5 rounded-xl">
      <h2 class="text-center text-xl font-bold">Чаты</h2>
      <p :if={@chats == []} class="text-[15px] text-tg-hint mt-2.5 text-center">Как одинокий зритель в пустом зале</p>
      <ul>
        <li :for={chat <- @chats} class="border-tg-section-separator border-b-2 pl-5 last:border-b-0">
          <p class="text-[15px] py-2.5">{chat.title}</p>
          <div class=" h-px"></div>
        </li>
      </ul>
    </section>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    chats = Accounts.list_user_chats(socket.assigns.current_user.id)
    {:ok, assign(socket, chats: chats)}
  end
end
