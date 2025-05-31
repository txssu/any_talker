defmodule AnyTalkerWeb.AuthHTML do
  use AnyTalkerWeb, :html

  @spec webapp_auth(map()) :: String.t()
  def webapp_auth(_params), do: ""
end
