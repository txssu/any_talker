defmodule AnyTalkerBot.RssFormatter do
  @moduledoc """
  Formats RSS article lists for Telegram display with pagination keyboard.
  """

  import ExGram.Dsl.Keyboard

  alias AnyTalkerBot.HtmlUtils

  require ExGram.Dsl.Keyboard

  @page_size 15

  @doc """
  Formats a page of articles into HTML text and an inline keyboard for navigation.

  Returns `{text, keyboard}` with navigation and a "mark read" button.
  `group_id_or_nil` is encoded in callback data (use `nil` for all-groups view).

  ## Example

      format_news_page(articles, 0, 42, nil)
      #=> {"● <a href=...>Title</a>\\n\\nСтраница 1 из 3", %ExGram.Model.InlineKeyboardMarkup{...}}

  """
  def format_news_page(articles, page, total_count, group_id_or_nil) do
    text = build_text(articles, page, total_count)
    keyboard = build_keyboard(page, total_count, group_id_or_nil)
    {text, keyboard}
  end

  @doc """
  Builds a single-button inline keyboard to mark all articles as read.

  Used after `/rss summary` output.

  ## Example

      mark_read_keyboard(nil)
      #=> %ExGram.Model.InlineKeyboardMarkup{...}

  """
  def mark_read_keyboard(group_id_or_nil) do
    group_str = encode_group(group_id_or_nil)

    keyboard :inline do
      row do
        button("Прочитано ✓", callback_data: "rss_read:#{group_str}")
      end
    end
  end

  defp build_text(articles, page, total_count) do
    total_pages = ceil(total_count / @page_size)
    lines = Enum.map_join(articles, "\n", &format_article/1)
    "#{lines}\n\nСтраница #{page + 1} из #{total_pages}"
  end

  defp format_article(%{url: url, title: title, read?: read?}) do
    bullet = if read?, do: "○", else: "●"
    safe_title = HtmlUtils.escape_html(title || "Без заголовка")
    "#{bullet} <a href=\"#{url}\">#{safe_title}</a>"
  end

  defp build_keyboard(page, total_count, group_id_or_nil) do
    total_pages = ceil(total_count / @page_size)
    group_str = encode_group(group_id_or_nil)
    nav_row = nav_buttons(page, total_pages, group_str)
    read_row = [%{text: "Прочитано ✓", callback_data: "rss_read:#{group_str}"}]
    refresh_row = [%{text: "Обновить", callback_data: "rss_refresh:#{group_str}"}]

    rows = if nav_row == [], do: [read_row, refresh_row], else: [nav_row, read_row, refresh_row]
    %ExGram.Model.InlineKeyboardMarkup{inline_keyboard: rows}
  end

  defp nav_buttons(_page, total_pages, _group_str) when total_pages <= 1, do: []

  defp nav_buttons(0, _total_pages, group_str), do: [%{text: "Вперёд →", callback_data: "rss_news:1:#{group_str}"}]

  defp nav_buttons(page, total_pages, group_str) when page >= total_pages - 1,
    do: [%{text: "← Назад", callback_data: "rss_news:#{page - 1}:#{group_str}"}]

  defp nav_buttons(page, _total_pages, group_str) do
    [
      %{text: "← Назад", callback_data: "rss_news:#{page - 1}:#{group_str}"},
      %{text: "Вперёд →", callback_data: "rss_news:#{page + 1}:#{group_str}"}
    ]
  end

  defp encode_group(nil), do: "0"
  defp encode_group(id), do: to_string(id)
end
