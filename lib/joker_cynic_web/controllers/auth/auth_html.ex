defmodule JokerCynicWeb.AuthHTML do
  use JokerCynicWeb, :html

  @spec via_webapp(map()) :: String.t()
  def via_webapp(_params), do: ""
end
