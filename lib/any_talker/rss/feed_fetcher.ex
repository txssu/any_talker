defmodule AnyTalker.RSS.FeedFetcher do
  @moduledoc """
  Fetches and parses an RSS or Atom feed URL. No database access — pure HTTP + parse.

  Tries RSS first, falls back to Atom if RSS parsing fails.

  ## Examples

      iex> fetch_and_parse("https://example.com/feed.xml")
      {:ok, %{title: "Example", entries: [%{url: "...", title: "...", content: "...", published_at: ~U[...]}]}}

  """

  @user_agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

  @doc """
  Fetches a URL, parses it as RSS or Atom, and returns the feed title and entries.

  Tries RSS first, falls back to Atom. Entries have `published_at` already parsed.
  Returns `{:error, reason}` if the HTTP request fails or the body is not a valid feed.

  ## Examples

      iex> fetch_and_parse("https://example.com/feed.xml")
      {:ok, %{title: "My Feed", entries: [%{url: "...", title: "...", content: "...", published_at: ~U[...]}]}}

  """
  def fetch_and_parse(url) do
    with {:ok, body} <- http_get(url) do
      case FastRSS.parse_rss(body) do
        {:ok, parsed} -> {:ok, normalize_rss(parsed)}
        {:error, _rss_err} -> parse_as_atom(body)
      end
    end
  end

  defp normalize_rss(parsed) do
    %{
      title: parsed["title"],
      entries: build_rss_entries(parsed["items"] || [])
    }
  end

  defp parse_as_atom(body) do
    case FastRSS.parse_atom(body) do
      {:ok, parsed} -> {:ok, normalize_atom(parsed)}
      {:error, _atom_err} -> {:error, :invalid_feed}
    end
  end

  defp normalize_atom(parsed) do
    %{
      title: get_in(parsed, ["title", "value"]),
      entries: build_atom_entries(parsed["entries"] || [])
    }
  end

  defp http_get(url) do
    case Tesla.get(client(), url) do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{status: status}} -> {:error, {:http_status, status}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp client do
    Tesla.client([
      {Tesla.Middleware.Headers, [{"user-agent", @user_agent}]},
      {Tesla.Middleware.Timeout, timeout: 15_000}
    ])
  end

  defp build_rss_entries(items) do
    items
    |> Enum.map(fn item ->
      url = item["link"] || ""

      %{
        url: url,
        guid: extract_rss_guid(item["guid"]) || url,
        title: item["title"],
        content: item["description"],
        published_at: parse_date(item["pub_date"])
      }
    end)
    |> Enum.reject(&(&1.url == ""))
  end

  defp extract_rss_guid(%{"value" => value}) when is_binary(value) and value != "", do: value
  defp extract_rss_guid(value) when is_binary(value) and value != "", do: value
  defp extract_rss_guid(_other), do: nil

  defp build_atom_entries(entries) do
    entries
    |> Enum.map(fn entry ->
      url = atom_entry_link(entry["links"] || [])

      %{
        url: url,
        guid: entry["id"] || url,
        title: get_in(entry, ["title", "value"]),
        content: atom_entry_content(entry),
        published_at: parse_date(entry["published"] || entry["updated"])
      }
    end)
    |> Enum.reject(&(&1.url == ""))
  end

  defp atom_entry_link(links) do
    link =
      Enum.find(links, List.first(links), fn l -> l["rel"] == "alternate" end)

    (link && link["href"]) || ""
  end

  defp atom_entry_content(entry) do
    get_in(entry, ["content", "value"]) ||
      get_in(entry, ["summary", "value"])
  end

  # -- Date parsing -----------------------------------------------------------

  defp parse_date(nil), do: nil

  defp parse_date(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, dt, _offset} -> ensure_usec(dt)
      _error -> parse_rfc2822(date_string)
    end
  end

  defp ensure_usec(%DateTime{microsecond: {_usec, 0}} = dt), do: %{dt | microsecond: {0, 6}}

  defp ensure_usec(dt), do: dt

  @months ~w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]

  defp parse_rfc2822(date_string) do
    with [_match, day, month_str, year, time_str, offset_str] <-
           Regex.run(
             ~r/(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}:\d{2}:\d{2})\s+([+-]\d{4}|GMT|UTC|Z)/,
             date_string
           ),
         {:ok, date} <- parse_date_parts(day, month_str, year),
         {:ok, time} <- parse_time_parts(time_str) do
      offset_secs = parse_offset(offset_str)
      naive_utc = DateTime.new!(date, time, "Etc/UTC")
      DateTime.add(naive_utc, -offset_secs, :second)
    else
      _error -> nil
    end
  rescue
    _error -> nil
  end

  defp parse_offset(offset_str) when offset_str in ["GMT", "UTC", "Z"], do: 0

  defp parse_offset(<<sign, h1, h2, m1, m2>>) do
    hours = String.to_integer(<<h1, h2>>)
    minutes = String.to_integer(<<m1, m2>>)
    total = hours * 3600 + minutes * 60
    if sign == ?+, do: total, else: -total
  end

  defp parse_offset(_unknown), do: 0

  defp parse_date_parts(day, month_str, year) do
    with {day_int, ""} <- Integer.parse(day),
         {year_int, ""} <- Integer.parse(year),
         month_idx when is_integer(month_idx) <-
           Enum.find_index(@months, &(&1 == month_str)) do
      Date.new(year_int, month_idx + 1, day_int)
    else
      _error -> :error
    end
  end

  defp parse_time_parts(time_str) do
    with [h, m, s] <- String.split(time_str, ":"),
         {hour, ""} <- Integer.parse(h),
         {min, ""} <- Integer.parse(m),
         {sec, ""} <- Integer.parse(s) do
      Time.new(hour, min, sec, {0, 6})
    else
      _error -> :error
    end
  end
end
