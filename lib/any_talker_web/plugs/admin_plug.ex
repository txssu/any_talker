defmodule AnyTalkerWeb.AdminPlug do
  @moduledoc false
  use AnyTalkerWeb, :verified_routes

  import Phoenix.Controller
  import Plug.Conn

  alias AnyTalker.Accounts

  def on_mount(:ensure_admin, _params, _session, socket) do
    user = socket.assigns.current_user

    if user.admin or Accounts.owner?(user) do
      {:cont, socket}
    else
      socket = Phoenix.LiveView.redirect(socket, to: ~p"/webapp")
      {:halt, socket}
    end
  end

  @doc """
  Used for routes that require the user to be an admin or owner.
  """
  def require_admin_user(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && (user.admin or Accounts.owner?(user)) do
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
