defmodule JokerCynicWeb.AuthPlug do
  @moduledoc false
  use JokerCynicWeb, :verified_routes

  import Phoenix.Controller
  import Plug.Conn

  alias JokerCynic.Accounts
  alias Phoenix.LiveView.Socket

  @spec valid_web_app_data?(map(), String.t()) :: boolean()
  def valid_web_app_data?(data, hash) do
    data_check_string =
      data
      |> Enum.to_list()
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map_join("\n", fn {key, value} -> "#{key}=#{value}" end)

    secret_key = :crypto.mac(:hmac, :sha256, "WebAppData", JokerCynicBot.Token.value())

    expected_hash =
      :hmac
      |> :crypto.mac(:sha256, secret_key, data_check_string)
      |> Base.encode16(case: :lower)

    expected_hash == hash
  end

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  @spec log_in_user(Plug.Conn.t(), Accounts.User.t()) :: Plug.Conn.t()
  def log_in_user(conn, user) do
    token = Accounts.create_token(user)

    conn
    |> renew_session()
    |> put_token_in_session(token)
  end

  defp renew_session(conn) do
    # Prevent a CSRF fixation attack. See https://hexdocs.pm/plug/Plug.CSRFProtection.html and https://github.com/phoenixframework/phoenix/pull/5725
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Authenticates the user by looking into the session.
  """
  @spec fetch_current_user(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_token(user_token)
    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      {nil, conn}
    end
  end

  @doc """
  Handles mounting and authenticating the current_user in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns current_user
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:ensure_authenticated` - Authenticates the user from the session,
      and assigns the current_user to socket assigns based
      on user_token.
      Redirects to login page if there's no logged user.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the session.
      Redirects to signed_in_path if there's a logged user.
  """
  @spec on_mount(atom(), Phoenix.LiveView.unsigned_params(), map(), Socket.t()) ::
          {:cont, Socket.t()} | {:halt, Socket.t()}
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket = Phoenix.LiveView.redirect(socket, to: ~p"/webapp/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user_token = session["user_token"] do
        Accounts.get_user_by_token(user_token)
      end
    end)
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  @spec redirect_if_user_is_authenticated(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  @spec require_authenticated_user(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> redirect(to: ~p"/webapp/log_in")
      |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    encoded_token = Base.url_encode64(token)

    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{encoded_token}")
  end

  defp signed_in_path(_conn), do: ~p"/webapp"
end
