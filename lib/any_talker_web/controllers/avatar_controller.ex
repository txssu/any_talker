defmodule AnyTalkerWeb.AvatarController do
  use AnyTalkerWeb, :controller

  alias AnyTalker.Settings

  def show(conn, %{"chat_id" => chat_id}) do
    case Integer.parse(chat_id) do
      {id, ""} ->
        case Settings.get_or_fetch_chat_avatar(id) do
          {:ok, avatar_blob} when is_binary(avatar_blob) ->
            conn
            |> put_resp_content_type("image/jpeg")
            |> put_resp_header("cache-control", "public, max-age=1800")
            |> send_resp(200, avatar_blob)

          {:ok, nil} ->
            send_resp(conn, 404, "No avatar found")

          {:error, _error_reason} ->
            send_resp(conn, 404, "Avatar not found")
        end

      _invalid_parse_result ->
        send_resp(conn, 400, "Invalid chat ID")
    end
  end
end
