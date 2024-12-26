defmodule JokerCynicWeb.AuthLive do
  @moduledoc false
  use JokerCynicWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <h1>Auth</h1>
      <script
        async
        src="https://telegram.org/js/telegram-widget.js?22"
        data-telegram-login="JokerCynicBot"
        data-size="large"
        data-auth-url={~p"/log_in/via_tg"}
        data-request-access="write"
      >
      </script>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
