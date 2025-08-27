defmodule AnyTalkerBot.Token do
  @moduledoc false

  def hash do
    :crypto.hash(:sha256, value())
  end

  def value do
    :any_talker
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:token)
  end
end
