defmodule AnyTalkerWeb.AdminPlug do
  @moduledoc false
  use AnyTalkerWeb, :verified_routes

  import Phoenix.Controller
  import Plug.Conn

  alias AnyTalker.Accounts

  def on_mount(:ensure_owner, _params, _session, socket) do
    if Accounts.owner?(socket.assigns.current_user) do
      {:cont, socket}
    else
      socket = Phoenix.LiveView.redirect(socket, to: ~p"/webapp")
      {:halt, socket}
    end
  end

  @doc """
  Used for routes that require the user to be an admin/owner.
  """
  def require_admin_user(conn, _opts) do
    if conn.assigns[:current_user] && Accounts.owner?(conn.assigns.current_user) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> put_view(Phoenix.Controller.ErrorHTML)
      |> render(:"403")
      |> halt()
    end
  end
end
