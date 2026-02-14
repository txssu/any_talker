defmodule AnyTalker.YouTube.YtExtractor do
  @moduledoc """
  Extracts video details and subtitles from YouTube using `yt-dlp --dump-json`.

  Uses the yt-dlp CLI tool to fetch video metadata as JSON, then extracts
  title, description, and subtitles following the priority order defined in subs.md.

  ## Configuration

  Set the version in `config.exs`:

      config :any_talker, yt_dlp_version: "2026.02.04"

  The binary is downloaded at compile time to `priv/bin/yt-dlp`.

  ## Subtitle priority

  1. `subtitles[language]` — author subtitles in the video's language
  2. `automatic_captions[language]` — auto-generated subtitles in the video's language
  3. `subtitles` with any other available language
  4. `automatic_captions` with any other available language

  Preferred subtitle format: `vtt`, fallback: `json3`.

  ## Examples

      iex> AnyTalker.YouTube.YtExtractor.get_video_details("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      {:ok, %AnyTalker.YouTube.YtExtractor.VideoDetails{title: "...", description: "...", subtitles: [...]}}
  """

  require Logger

  @bin_dir :any_talker
           |> :code.priv_dir()
           |> Path.join("bin")
  @bin_path Path.join(@bin_dir, "yt-dlp")
  @external_resource @bin_path

  if !File.exists?(@bin_path) and Mix.env() != :test do
    version = Application.compile_env!(:any_talker, :yt_dlp_version)
    yt_dlp_url = "https://github.com/yt-dlp/yt-dlp/releases/download/#{version}/yt-dlp"

    Mix.shell().info("Downloading yt-dlp #{version} from #{yt_dlp_url}")
    File.mkdir_p!(@bin_dir)

    {_output, 0} = System.cmd("curl", ["-fSL", "-o", @bin_path, yt_dlp_url], env: [])
    File.chmod!(@bin_path, 0o755)

    Mix.shell().info("yt-dlp #{version} installed at #{@bin_path}")
  end

  defp bin_dir do
    :any_talker
    |> :code.priv_dir()
    |> Path.join("bin")
  end

  @doc """
  Returns the path to the yt-dlp binary.
  """
  def bin_path do
    Path.join(bin_dir(), "yt-dlp")
  end

  defmodule Subtitle do
    @moduledoc """
    Represents a single subtitle entry.

    ## Fields

    | Field Name | Type   | Description                         |
    |------------|--------|-------------------------------------|
    | start      | String | Start time in seconds               |
    | duration   | String | Duration in seconds                 |
    | text       | String | Decoded subtitle text               |
    """

    defstruct [:start, :duration, :text]
  end

  defmodule VideoDetails do
    @moduledoc """
    Represents video details including metadata and subtitles.

    ## Fields

    | Field Name       | Type              | Description                              |
    |------------------|-------------------|------------------------------------------|
    | title            | String            | Video title                              |
    | description      | String            | Video description                        |
    | subtitles        | List of Subtitle  | List of subtitle entries                 |
    | transcript_error | String or nil     | Error message if transcript unavailable  |
    """

    defstruct [:title, :description, :transcript_error, subtitles: []]
  end

  @doc """
  Fetches video details including title, description, and subtitles.

  Accepts a YouTube URL or video ID.

  ## Parameters

    * `video_url_or_id` - YouTube URL or video ID
    * `lang` - Preferred language code (default: uses video's original language)

  ## Examples

      iex> get_video_details("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      {:ok, %VideoDetails{title: "...", description: "...", subtitles: [...]}}

      iex> get_video_details("dQw4w9WgXcQ")
      {:ok, %VideoDetails{title: "...", description: "...", subtitles: [...]}}
  """
  def get_video_details(video_url_or_id, lang \\ nil) do
    with {:ok, json} <- run_yt_dlp(video_url_or_id) do
      preferred_lang = lang || json["language"] || "en"
      build_video_details(json, video_url_or_id, preferred_lang)
    end
  end

  @doc """
  Fetches only subtitles for a video.

  ## Parameters

    * `video_url_or_id` - YouTube URL or video ID
    * `lang` - Preferred language code (default: uses video's original language)

  ## Examples

      iex> get_subtitles("dQw4w9WgXcQ")
      {:ok, [%Subtitle{start: "0.0", duration: "1.5", text: "..."}]}
  """
  def get_subtitles(video_url_or_id, lang \\ nil) do
    with {:ok, json} <- run_yt_dlp(video_url_or_id) do
      preferred_lang = lang || json["language"] || "en"
      extract_subtitles(json, preferred_lang)
    end
  end

  ## Private

  defp build_video_details(json, video_url_or_id, lang) do
    title = json["title"] || json["fulltitle"] || "No title found"
    description = json["description"] || "No description found"

    case extract_subtitles(json, lang) do
      {:ok, subtitles} ->
        {:ok, %VideoDetails{title: title, description: description, subtitles: subtitles}}

      {:error, reason} ->
        Logger.warning("Could not fetch subtitles via yt-dlp",
          details: %{url: video_url_or_id, reason: reason}
        )

        {:ok,
         %VideoDetails{
           title: title,
           description: description,
           subtitles: [],
           transcript_error: reason
         }}
    end
  end

  # sobelow_skip ["CI.System"]
  defp run_yt_dlp(video_url_or_id) do
    url = normalize_url(video_url_or_id)
    args = ["--dump-json", "--no-warnings", "--no-playlist", "--skip-download", url]

    Logger.debug("Running yt-dlp", details: %{url: url})

    case System.cmd(bin_path(), args, stderr_to_stdout: true, env: []) do
      {output, 0} -> decode_yt_dlp_output(output)
      {output, _exit_code} -> {:error, "yt-dlp failed: #{String.slice(output, 0, 200)}"}
    end
  end

  defp decode_yt_dlp_output(output) do
    case Jason.decode(output) do
      {:ok, json} -> {:ok, json}
      {:error, _reason} -> {:error, "Failed to parse yt-dlp JSON output"}
    end
  end

  defp normalize_url(url_or_id) do
    if String.contains?(url_or_id, "://") do
      url_or_id
    else
      "https://www.youtube.com/watch?v=#{url_or_id}"
    end
  end

  defp extract_subtitles(json, lang) do
    subtitles_map = json["subtitles"] || %{}
    auto_captions_map = json["automatic_captions"] || %{}

    case find_subtitle_url(subtitles_map, auto_captions_map, lang) do
      {:ok, url} -> fetch_and_parse_subtitle(url)
      {:error, reason} -> {:error, reason}
    end
  end

  defp find_subtitle_url(subtitles, auto_captions, lang) do
    with :not_found <- find_format_url(subtitles, lang),
         :not_found <- find_format_url(auto_captions, lang),
         :not_found <- find_any_language_url(subtitles),
         :not_found <- find_any_language_url(auto_captions) do
      {:error, "No subtitles available"}
    end
  end

  defp find_format_url(tracks, lang) when map_size(tracks) == 0 when not is_map_key(tracks, lang) do
    :not_found
  end

  defp find_format_url(tracks, lang) do
    tracks
    |> Map.get(lang, [])
    |> pick_best_format()
  end

  defp find_any_language_url(tracks) when map_size(tracks) == 0, do: :not_found

  defp find_any_language_url(tracks) do
    tracks
    |> Map.values()
    |> Enum.find_value(:not_found, fn formats ->
      case pick_best_format(formats) do
        {:ok, _url} = result -> result
        :not_found -> nil
      end
    end)
  end

  defp pick_best_format(formats) when is_list(formats) do
    preferred = Enum.find(formats, &(&1["ext"] == "vtt"))
    fallback = Enum.find(formats, &(&1["ext"] == "json3"))
    chosen = preferred || fallback || List.first(formats)

    case chosen do
      %{"url" => url} when is_binary(url) -> {:ok, url}
      _other -> :not_found
    end
  end

  defp pick_best_format(_formats), do: :not_found

  defp fetch_and_parse_subtitle(url) do
    Logger.debug("Fetching subtitle content", details: %{url: String.slice(url, 0, 100)})

    case fetch_url(url) do
      {:ok, body} -> {:ok, parse_vtt(body)}
      {:error, reason} -> {:error, "Failed to download subtitles: #{reason}"}
    end
  end

  defp fetch_url(url) do
    client =
      Tesla.client([
        {Tesla.Middleware.Headers,
         [
           {"User-Agent",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"}
         ]}
      ])

    case Tesla.get(client, url) do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{status: status}} -> {:error, "HTTP #{status}"}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  defp parse_vtt(body) do
    body
    |> String.split("\n\n")
    |> Enum.flat_map(&parse_vtt_block/1)
    |> Enum.uniq_by(& &1.text)
  end

  defp parse_vtt_block(block) do
    lines = String.split(block, "\n", trim: true)

    with {timestamp_line, text_lines} when text_lines != [] <- find_timestamp_line(lines),
         {:ok, start_sec, end_sec} <- parse_vtt_timestamp(timestamp_line),
         text when text != "" <- build_subtitle_text(text_lines) do
      duration = max(end_sec - start_sec, 0.0)

      [
        %Subtitle{
          start: Float.to_string(start_sec),
          duration: Float.to_string(duration),
          text: text
        }
      ]
    else
      _other -> []
    end
  end

  defp build_subtitle_text(text_lines) do
    text_lines
    |> Enum.join(" ")
    |> strip_vtt_tags()
    |> String.trim()
  end

  defp find_timestamp_line(lines) do
    case Enum.split_while(lines, &(not String.contains?(&1, " --> "))) do
      {_before, [timestamp | text]} -> {timestamp, text}
      _other -> :not_found
    end
  end

  defp parse_vtt_timestamp(line) do
    case Regex.run(~r/(\d[\d:.]+)\s*-->\s*(\d[\d:.]+)/, line) do
      [_full, start_str, end_str] ->
        {:ok, vtt_time_to_seconds(start_str), vtt_time_to_seconds(end_str)}

      _no_match ->
        :error
    end
  end

  defp vtt_time_to_seconds(time_str) do
    time_str
    |> String.split(":")
    |> parse_time_parts()
  end

  defp parse_time_parts([h, m, s]) do
    parse_float(h) * 3600 + parse_float(m) * 60 + parse_float(s)
  end

  defp parse_time_parts([m, s]) do
    parse_float(m) * 60 + parse_float(s)
  end

  defp parse_time_parts(_other), do: 0.0

  defp parse_float(s) do
    s
    |> pad_decimal()
    |> String.to_float()
  end

  defp pad_decimal(s) do
    if String.contains?(s, "."), do: s, else: s <> ".0"
  end

  defp strip_vtt_tags(text) do
    text
    |> String.replace(~r/<[^>]+>/, "")
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
  end
end
