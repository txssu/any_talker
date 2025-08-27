defmodule AnyTalkerWeb.CSPNoncePlug do
  @moduledoc """
  Set a CSP nonce for the current request.
  """

  def init(options), do: options

  def call(conn, opts) do
    nonce = Keyword.get(opts, :nonce)

    Plug.Conn.assign(conn, :csp_nonce, nonce)
  end
end
