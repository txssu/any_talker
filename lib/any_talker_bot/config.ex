defmodule AnyTalkerBot.Config do
  @moduledoc false
  def bot_token, do: get(:bot_token)

  def owner_id, do: get(:owner_id)

  def payment_provider_token, do: get(:payment_provider_token)

  defp get(key) do
    :any_talker
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
