defmodule AnyTalker.ImportData do
  @moduledoc false
  alias AnyTalker.Events

  def import_from_stream(bin_stream, chat_id) do
    {json_stream, _data} = JSONStream.stream(bin_stream, ["messages"])

    json_stream
    |> Stream.map(&convert(&1, chat_id))
    |> Stream.reject(&is_nil/1)
    |> Events.save_imported_messages()
  end

  defp convert(message, chat_id) do
    if from_id = convert_from_id(message["from_id"]) do
      utc_datetime =
        message["date_unixtime"]
        |> String.to_integer()
        |> DateTime.from_unix!()

      text = join_text(message["text"])

      from = from_with_default(message["from"])

      %Events.Message{
        message_id: message["id"],
        name_from_import: from,
        chat_id: chat_id,
        source: :export,
        from_id: from_id,
        text: text,
        sent_date: utc_datetime
      }
    end
  end

  defp from_with_default(:null), do: nil
  defp from_with_default(text), do: text

  defp join_text(text) when is_binary(text), do: text

  defp join_text(list) when is_list(list) do
    Enum.map_join(list, fn
      %{"text" => text} -> text
      text -> text
    end)
  end

  defp convert_from_id("user" <> id_str) do
    case Integer.parse(id_str) do
      {id, ""} -> id
      _error -> nil
    end
  end

  defp convert_from_id(_id), do: nil
end
