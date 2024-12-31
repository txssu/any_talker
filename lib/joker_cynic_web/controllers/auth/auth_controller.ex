defmodule JokerCynicWeb.AuthController do
  use JokerCynicWeb, :controller

  @spec webapp(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def webapp(conn, _params) do
    render(conn, :webapp_auth, auth: true)
  end

  @spec via_webapp(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def via_webapp(conn, %{"hash" => hash, "user" => user} = params) do
    data = Map.delete(params, "hash")

    if JokerCynicWeb.AuthPlug.valid_web_app_data?(data, hash) do
      attrs = Jason.decode!(user)

      {:ok, user} =
        attrs
        |> Map.take(~w[id username first_name last_name])
        |> JokerCynic.Accounts.upsert_user()

      {:ok, user} = JokerCynic.Accounts.update_user(user, attrs)

      conn
      |> JokerCynicWeb.AuthPlug.log_in_user(user)
      |> redirect(to: ~p"/webapp")
    else
      text(conn, "ERROR")
    end
  end

  @spec via_webapp(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def via_webapp(conn, _params) do
    redirect(conn, to: ~p"/webapp")
  end
end
