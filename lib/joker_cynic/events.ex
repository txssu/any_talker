defmodule JokerCynic.Events do
  @moduledoc false

  alias JokerCynic.Events.SentMessage
  alias JokerCynic.Events.Update
  alias JokerCynic.Repo

  @spec save_update(integer() | String.t(), map()) :: :ok
  def save_update(id, update) do
    value = remove_deep_nils(update)

    %Update{id: id, value: value}
    |> Ecto.Changeset.change()
    # Ignore already saved updates.
    # Telegram sends updates again if bot can't process them.
    |> Ecto.Changeset.unique_constraint(:id, name: "updates_pkey")
    |> Repo.insert()

    :ok
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
