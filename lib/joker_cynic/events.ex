defmodule JokerCynic.Events do
  @moduledoc false

  alias JokerCynic.Events.SentMessage
  alias JokerCynic.Events.Update
  alias JokerCynic.Repo

  @spec save_update(integer() | String.t(), map()) :: {:ok, Update.t()}
  def save_update(id, update) do
    value = remove_deep_nils(update)
    Repo.insert(%Update{id: id, value: value})
  end

  @spec save_sent_message(integer() | String.t(), map()) :: {:ok, SentMessage.t()}
  def save_sent_message(id, message) do
    value = remove_deep_nils(message)
    Repo.insert(%SentMessage{id: id, value: value})
  end

  defp remove_deep_nils(map) when is_map(map) do
    map
    |> Map.from_struct()
    |> Map.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new(fn {k, v} -> {k, remove_deep_nils(v)} end)
  end

  defp remove_deep_nils(list) when is_list(list) do
    list
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&remove_deep_nils/1)
  end

  defp remove_deep_nils(value), do: value
end
