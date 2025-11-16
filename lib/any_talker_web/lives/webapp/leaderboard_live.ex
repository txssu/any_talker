defmodule AnyTalkerWeb.WebApp.LeaderboardLive do
  @moduledoc false
  use AnyTalkerWeb, :live_view

  import AnyTalkerWeb.TelegramComponents

  alias AnyTalker.Game

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="back-init" phx-hook="TelegramBack" data-state="on"></div>
    <.section class="pt-[30px] pb-[15px]">
      <h1 class="mt-[15px] text-center text-xl font-bold">Скорборд /move</h1>
    </.section>

    <.leaderboard_section players={@players} />
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    players = Game.top_players(50)

    {:ok, assign(socket, players: players)}
  end
end
