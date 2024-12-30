defmodule JokerCynicWeb.WebApp.MenuLive do
  @moduledoc false
  use JokerCynicWeb, :live_view

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
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
