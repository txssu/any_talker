defmodule JokerCynicWeb.WebApp.MenuLive do
  @moduledoc false
  use JokerCynicWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <p class="text-center text-2xl">
        Welcome, {@current_user.first_name}!
      </p>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
