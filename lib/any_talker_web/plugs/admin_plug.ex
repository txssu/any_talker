defmodule AnyTalkerWeb.AdminPlug do
  @moduledoc false
  use AnyTalkerWeb, :verified_routes

  alias AnyTalker.Accounts

  def on_mount(:ensure_owner, _params, _session, socket) do
    if Accounts.owner?(socket.assigns.current_user) do
      {:cont, socket}
    else
      socket = Phoenix.LiveView.redirect(socket, to: ~p"/webapp")
      {:halt, socket}
    end
  end
end
