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

    <.users_section users={@users} />
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    users = Accounts.list_users()

    {:ok, assign(socket, users: users)}
  end
end
