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
end
