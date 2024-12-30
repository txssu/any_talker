defmodule JokerCynicWeb.AuthController do
  use JokerCynicWeb, :controller

  @spec via_tg(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def via_tg(conn, params) do
    if JokerCynicWeb.AuthPlug.valid_hash?(params) do
      conn
      |> put_flash(:info, gettext("Logged in successfully"))
      |> JokerCynicWeb.AuthPlug.log_in_user()
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, gettext("Please try again"))
      |> redirect(to: ~p"/log_in")
    end
  end

  @spec webapp(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def webapp(conn, _params) do
    conn
    |> put_layout(html: :webapp)
    |> render(:via_webapp, auth: true)
  end

  @spec via_webapp(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def via_webapp(conn, %{"hash" => hash} = params) do
    data = Map.delete(params, "hash")

    if JokerCynicWeb.AuthPlug.valid_web_app_data?(data, hash) do
      conn
      |> JokerCynicWeb.AuthPlug.log_in_api_user()
      |> text("OK")
    else
      text(conn, "ERROR")
    end
  end

  @spec via_webapp(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def via_webapp(conn, _params) do
    redirect(conn, to: ~p"/webapp")
  end
end
