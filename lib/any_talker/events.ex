defmodule AnyTalker.Events do
  @moduledoc false

  import Ecto.Query

  alias AnyTalker.Accounts.ChatMember
  alias AnyTalker.Events
  alias AnyTalker.Events.Update
  alias AnyTalker.Repo
  alias ExGram.Model.Message

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

  def list_move_messages(date \\ ~U[2025-10-28 00:00:00Z]) do
    Events.Message
    |> where([m], like(m.text, "/move%"))
    |> where([m], m.sent_date >= ^date)
    |> order_by([m], asc: m.sent_date)
    |> Repo.all()
  end

  # Границы периодов (в UTC, т.к. Екатеринбург = UTC+5)
  # 28.10.2025 00:00 EKB = 27.10.2025 19:00 UTC
  @start_date ~U[2025-10-27 19:00:00Z]
  # 31.12.2025 00:00 EKB = 30.12.2025 19:00 UTC
  @dec_31_start ~U[2025-12-30 19:00:00Z]
  # 01.01.2026 00:00 EKB = 31.12.2025 19:00 UTC
  @jan_1_start ~U[2025-12-31 19:00:00Z]

  def analyze_move_stats do
    @start_date
    |> list_move_messages()
    |> Enum.group_by(& &1.from_id)
    |> Enum.map(&build_user_stats/1)
  end

  def populate_move_stats do
    Enum.each(analyze_move_stats(), fn stats ->
      %Events.MoveStats{user_id: stats.user_id}
      |> Events.MoveStats.changeset(stats)
      |> Repo.insert(
        conflict_target: [:user_id],
        on_conflict: {:replace, [:forwards, :left, :right]}
      )
    end)
  end

  defp build_user_stats({user_id, messages}) do
    {before_dec_31, rest} = Enum.split_with(messages, &DateTime.before?(&1.sent_date, @dec_31_start))
    {dec_31_msgs, _jan_1_msgs} = Enum.split_with(rest, &DateTime.before?(&1.sent_date, @jan_1_start))

    {forwards_1h, lefts_1h, rights_1h} = count_by_windows(before_dec_31, 1)
    {forwards_3h, lefts_3h, rights_3h} = count_by_windows(dec_31_msgs, 3)

    %{
      user_id: user_id,
      forwards: forwards_1h + forwards_3h,
      left: lefts_1h + lefts_3h,
      right: rights_1h + rights_3h
    }
  end

  defp count_by_windows(messages, window_hours) do
    {fwd, left, right} =
      Enum.reduce(messages, {MapSet.new(), MapSet.new(), MapSet.new()}, fn msg, acc ->
        classify_message(msg, window_hours, acc)
      end)

    {MapSet.size(fwd), MapSet.size(left), MapSet.size(right)}
  end

  defp classify_message(msg, window_hours, {fwd, left, right}) do
    ekb_time = DateTime.shift_zone!(msg.sent_date, "Asia/Yekaterinburg")
    key = {DateTime.to_date(ekb_time), div(ekb_time.hour, window_hours)}

    cond do
      forward?(msg) -> {MapSet.put(fwd, key), left, right}
      left?(msg) -> {fwd, MapSet.put(left, key), right}
      right?(msg) -> {fwd, left, MapSet.put(right, key)}
      true -> {fwd, left, right}
    end
  end

  defp forward?(msg), do: String.contains?(msg.text || "", "forward")
  defp left?(msg), do: String.contains?(msg.text || "", "left")
  defp right?(msg), do: String.contains?(msg.text || "", "right")

  @doc """
  Returns move stats for users in a specific chat, ordered by forwards descending.

  ## Examples

      iex> list_move_stats_for_chat(-1001234567890)
      [%MoveStats{user: %User{}, forwards: 10, left: 5, right: 3}, ...]

  """
  def list_move_stats_for_chat(chat_id) do
    Events.MoveStats
    |> join(:inner, [ms], cm in ChatMember, on: cm.user_id == ms.user_id)
    |> where([_ms, cm], cm.chat_id == ^chat_id)
    |> order_by([ms], desc: ms.forwards)
    |> preload(:user)
    |> Repo.all()
  end
end
