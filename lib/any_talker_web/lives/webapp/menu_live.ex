defmodule AnyTalkerWeb.WebApp.MenuLive do
  @moduledoc false
  use AnyTalkerWeb, :live_view

  import AnyTalkerWeb.TelegramComponents

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.Subscription
  alias AnyTalker.BuildInfo

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="back-init" phx-hook="TelegramBack" data-state="off"></div>
    <.section class="pt-[30px] pb-[15px]">
      <div class="flex justify-center">
        <img src={@current_user.photo_url} class="rounded-full" width="90" height="90" alt="User photo" />
      </div>
      <h1 class="mt-[15px] text-center text-xl font-bold">Добро пожаловать, {Accounts.display_name(@current_user)}!</h1>
      <p class="text-tg-hint mt-2.5 text-center text-sm">{subscription_status_text(@subscription)}</p>
    </.section>

    <.section :if={@user_owner?} class="mt-5">
      <:header>Админка</:header>
      <ul>
        <li>
          <.link
            navigate={~p"/webapp/global"}
            class="border-tg-section-separator hover-effect h-[42px] flex items-center rounded-lg border-b-2 pl-5 last:border-b-0"
          >
            <span class="text-[15px] py-2.5">Глобальный конфиг</span>
          </.link>
        </li>
        <li>
          <.link
            navigate={~p"/webapp/users"}
            class="border-tg-section-separator hover-effect h-[42px] flex items-center rounded-lg border-b-2 pl-5 last:border-b-0"
          >
            <span class="text-[15px] py-2.5">Пользователи</span>
          </.link>
        </li>
      </ul>
      <p class="text-tg-hint mt-2 text-center text-xs">Версия {BuildInfo.git_short_hash()}</p>
    </.section>

    <.section class="mt-5">
      <:header>Аккаунт</:header>
      <ul>
        <li>
          <.link
            navigate={~p"/webapp/profile"}
            class="border-tg-section-separator hover-effect h-[42px] flex items-center rounded-lg border-b-2 pl-5 last:border-b-0"
          >
            <span class="text-[15px] py-2.5">Настройки</span>
          </.link>
        </li>
      </ul>
    </.section>

    <.section class="mt-5">
      <:header>Чаты</:header>
      <p :if={@chats == []} class="text-[15px] text-tg-hint mt-2.5 text-center">Как одинокий зритель в пустом зале</p>
      <ul>
        <li :for={chat <- @chats}>
          <.link
            navigate={~p"/webapp/c/#{chat.id}"}
            class="border-tg-section-separator hover-effect h-[42px] flex items-center rounded-lg border-b-2 pl-5 last:border-b-0"
          >
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
    user_owner? = Accounts.owner?(socket.assigns.current_user)
    subscription = Accounts.get_current_subscription(socket.assigns.current_user)
    {:ok, assign(socket, chats: chats, user_owner?: user_owner?, subscription: subscription)}
  end

  defp subscription_status_text(%Subscription{expires_at: nil}), do: "Подписка бессрочная"

  defp subscription_status_text(%Subscription{expires_at: %DateTime{} = expires_at}) do
    expires_at
    |> DateTime.shift_zone!("Asia/Yekaterinburg")
    |> Calendar.strftime("Подписка до %d.%m.%Y")
  end

  defp subscription_status_text(nil), do: "Нет подписки"
end
