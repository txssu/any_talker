defmodule AnyTalkerWeb.AvatarController do
  use AnyTalkerWeb, :controller

  alias AnyTalker.Accounts
  alias AnyTalker.AvatarGenerator
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

  def user(conn, %{"user_id" => user_id}) do
    case Integer.parse(user_id) do
      {id, ""} ->
        case Accounts.get_user(id) do
          nil ->
            send_resp(conn, 404, "User not found")

          user ->
            svg = AvatarGenerator.generate(user.first_name, user.last_name, user.id)

            conn
            |> put_resp_content_type("image/svg+xml")
            |> put_resp_header("cache-control", "public, max-age=3600")
            |> send_resp(200, svg)
        end

      _invalid_parse_result ->
        send_resp(conn, 400, "Invalid user ID")
    end
  end
end
