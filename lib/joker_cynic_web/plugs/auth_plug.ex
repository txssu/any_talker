defmodule JokerCynicWeb.AuthPlug do
  @moduledoc false
  use JokerCynicWeb, :verified_routes

  import Phoenix.Controller
  import Plug.Conn

  @spec valid_hash?(map()) :: boolean()
  def valid_hash?(fields) do
    hash = Map.fetch!(fields, "hash")

    data_check_string =
      fields
      |> Map.delete("hash")
      |> Enum.to_list()
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map_join("\n", fn {key, value} -> "#{key}=#{value}" end)

    secret_key = JokerCynicBot.Token.hash()

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
  @spec log_in_user(Plug.Conn.t()) :: Plug.Conn.t()
  def log_in_user(conn) do
    user_return_to = get_session(conn, :user_return_to)
    token = :crypto.strong_rand_bytes(32)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    # Prevent a CSRF fixation attack. See https://hexdocs.pm/plug/Plug.CSRFProtection.html and https://github.com/phoenixframework/phoenix/pull/5725
    delete_csrf_token()

    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  defp put_token_in_session(conn, token) do
    encoded_token = Base.url_encode64(token)

    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{encoded_token}")
  end

  defp signed_in_path(_conn), do: ~p"/log_in"
end
