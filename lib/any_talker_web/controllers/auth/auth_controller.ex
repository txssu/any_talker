defmodule AnyTalkerWeb.AuthController do
  use AnyTalkerWeb, :controller

  def webapp(conn, _params) do
    render(conn, :webapp_auth, auth: true)
  end

  def via_webapp(conn, %{"hash" => hash, "user" => user} = params) do
    data = Map.delete(params, "hash")

    if AnyTalkerWeb.AuthPlug.valid_web_app_data?(data, hash) do
      attrs = Jason.decode!(user)

      {:ok, user} = AnyTalker.Accounts.upsert_user(attrs, ~w[username first_name last_name photo_url]a)

      conn
      |> AnyTalkerWeb.AuthPlug.log_in_user(user)
      |> redirect(to: ~p"/webapp")
    else
      text(conn, "ERROR")
    end
  end

  def via_webapp(conn, _params) do
    redirect(conn, to: ~p"/webapp")
  end
end
