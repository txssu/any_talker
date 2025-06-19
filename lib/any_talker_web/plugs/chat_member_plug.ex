defmodule AnyTalkerWeb.ChatMemberPlug do
  @moduledoc false
  import Plug.Conn

  alias AnyTalker.Accounts

  @spec require_chat_member(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def require_chat_member(conn, _opts) do
    with chat_id when is_binary(chat_id) <- conn.path_params["chat_id"],
         {id, ""} <- Integer.parse(chat_id),
         %{id: user_id} <- conn.assigns[:current_user],
         true <- Accounts.chat_member?(user_id, id) do
      conn
    else
      _error ->
        conn
        |> send_resp(404, "Not found")
        |> halt()
    end
  end
end
