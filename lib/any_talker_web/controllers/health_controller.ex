defmodule AnyTalkerWeb.HealthController do
  @moduledoc """
  Health check controller for monitoring and load balancers.
  """

  use AnyTalkerWeb, :controller

  @doc """
  Returns 200 OK when the application is running.
  """
  def index(conn, _params) do
    send_resp(conn, 200, "ok")
  end
end
