defmodule AnyTalker.Events do
  @moduledoc false

  alias AnyTalker.Events
  alias AnyTalker.Events.Update
  alias AnyTalker.Repo
  alias ExGram.Model.Message

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

  @spec save_new_message(Message.t()) :: :ok
  def save_new_message(%Message{} = message) do
    utc_datetime = DateTime.from_unix!(message.date)

    %Events.Message{
      message_id: message.message_id,
      chat_id: message.chat.id,
      source: :telegram,
      from_id: message.from.id,
      text: message.text,
      sent_date: utc_datetime
    }
    |> Ecto.Changeset.change()
    # Set new data for already saved received messages.
    # Telegram sends updates again if bot can't process them.
    |> Ecto.Changeset.unique_constraint(:message_id_chat_id, name: "messages_pkey")
    |> Repo.insert(
      conflict_target: [:message_id, :chat_id],
      on_conflict: {:replace_all_except, [:message_id, :chat_id]}
    )

    :ok
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
