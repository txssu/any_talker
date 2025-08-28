defmodule AnyTalkerWeb.NikitaPlayerController do
  @moduledoc """
  Controller for Nikita Player long polling endpoint.
  """

  use AnyTalkerWeb, :controller

  @doc """
  Long polling endpoint for player commands.

  Returns "PLAY 1", "STOP", or "" depending on player state and commands.
  Polls for up to 30 seconds.
  """
  @spec poll(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def poll(conn, _params) do
    case AnyTalker.NikitaPlayer.poll() do
      command when is_binary(command) ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, command)
    end
  end
end
