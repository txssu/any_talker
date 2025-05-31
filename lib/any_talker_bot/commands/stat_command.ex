defmodule AnyTalkerBot.StatCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  import AnyTalkerBot.MarkdownUtils, only: [escape_markdown: 1, sigil_i: 2]

  alias AnyTalker.Statistics
  alias AnyTalkerBot.Reply

  @impl AnyTalkerBot.Command
  def call(%Reply{} = reply) do
    {:command, :stat, message} = reply.message
    top_authors = Statistics.get_top_message_authors_today(message.chat.id, 5)

    text = format_response(top_authors)
    %{reply | text: text, for_dm: true, markdown: true}
  end

  defp format_response([]) do
    ~i"Нет сообщений за сегодня\."
  end

  defp format_response(authors) do
    today = Date.utc_today()
    formatted_date = Calendar.strftime(today, "%d.%m.%Y")

    header = ~i"Топ 3 авторов сообщений за #{formatted_date}:"

    authors_text =
      authors
      |> Enum.with_index(1)
      |> Enum.map_join("\n", fn {%{from_id: from_id, message_count: count, user: user}, index} ->
        username = if user, do: user.username || user.first_name, else: "Неизвестный пользователь"
        display_name = escape_markdown(username)

        msg_text = get_message_word(count)
        ~i"#{index}\. [#{display_name}](tg://user?id=#{from_id}) — #{count} #{msg_text}"
      end)

    "#{header}\n\n#{authors_text}"
  end

  defp get_message_word(count) when rem(count, 100) >= 11 and rem(count, 100) <= 19, do: "сообщений"
  defp get_message_word(count) when rem(count, 10) == 1, do: "сообщение"
  defp get_message_word(count) when rem(count, 10) >= 2 and rem(count, 10) <= 4, do: "сообщения"
  defp get_message_word(_count), do: "сообщений"
end
