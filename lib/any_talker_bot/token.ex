defmodule AnyTalkerBot.Token do
  @moduledoc false

  @spec hash() :: String.t()
  def hash do
    :crypto.hash(:sha256, value())
  end

  @spec value() :: String.t()
  def value do
    :any_talker
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:token)
  end
end
