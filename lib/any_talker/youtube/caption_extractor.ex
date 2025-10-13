defmodule AnyTalker.YouTube.CaptionExtractor do
  @moduledoc """
  Extracts captions and video details from YouTube videos using the InnerTube API.

  This module provides functionality to fetch video titles, descriptions, and subtitles
  from YouTube videos. It uses two methods:
  1. Transcript API via engagement panels (preferred)
  2. Traditional caption tracks (fallback)

  ## Examples

      iex> AnyTalker.YouTube.CaptionExtractor.get_video_details("dQw4w9WgXcQ")
      {:ok, %{title: "...", description: "...", subtitles: [...]}}

      iex> AnyTalker.YouTube.CaptionExtractor.get_subtitles("dQw4w9WgXcQ", "en")
      {:ok, [%{start: "0.0", duration: "1.5", text: "..."}]}
  """

  alias AnyTalker.YouTube.Client

  require Logger

  @client_config %{
    web: %{
      name: "WEB",
      version: "2.20250222.10.00"
    },
    android: %{
      name: "ANDROID",
      version: "19.35.36"
    }
  }

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

    @type t :: %__MODULE__{
            start: String.t(),
            duration: String.t(),
            text: String.t()
          }

    defstruct [:start, :duration, :text]
  end

  defmodule VideoDetails do
    @moduledoc """
    Represents video details including metadata and subtitles.

    ## Fields

    | Field Name  | Type              | Description                     |
    |-------------|-------------------|---------------------------------|
    | title       | String            | Video title                     |
    | description | String            | Video description               |
    | subtitles   | List of Subtitle  | List of subtitle entries        |
    """

    @type t :: %__MODULE__{
            title: String.t(),
            description: String.t(),
            subtitles: [Subtitle.t()]
          }

    defstruct [:title, :description, subtitles: []]
  end

  ## Public API

  @doc """
  Fetches video details including title, description, and subtitles.

  Accepts either a video ID or a YouTube URL.

  ## Parameters

    * `video_id_or_url` - YouTube video ID or URL
    * `lang` - Language code (default: "ru")

  ## Examples

      iex> get_video_details("dQw4w9WgXcQ")
      {:ok, %VideoDetails{title: "...", description: "...", subtitles: [...]}}

      iex> get_video_details("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      {:ok, %VideoDetails{title: "...", description: "...", subtitles: [...]}}

      iex> get_video_details("https://youtu.be/dQw4w9WgXcQ")
      {:ok, %VideoDetails{title: "...", description: "...", subtitles: [...]}}

      iex> get_video_details("invalid")
      {:error, "Player API failed: 400 Bad Request"}
  """
  @spec get_video_details(String.t(), String.t()) :: {:ok, VideoDetails.t()} | {:error, String.t()}
  def get_video_details(video_id_or_url, lang \\ "ru") do
    with {:ok, video_id} <- extract_video_id(video_id_or_url),
         {:ok, %{player_data: player_data, next_data: next_data}} <- fetch_video_info(video_id),
         {:ok, title} <- extract_title(player_data, next_data),
         {:ok, description} <- extract_description(player_data, next_data),
         {:ok, subtitles} <- fetch_subtitles_with_fallback(video_id, player_data, next_data, lang) do
      {:ok, %VideoDetails{title: title, description: description, subtitles: subtitles}}
    end
  end

  @doc """
  Fetches only subtitles for a video.

  Accepts either a video ID or a YouTube URL.

  ## Parameters

    * `video_id_or_url` - YouTube video ID or URL
    * `lang` - Language code (default: "ru")

  ## Examples

      iex> get_subtitles("dQw4w9WgXcQ")
      {:ok, [%Subtitle{start: "0.0", duration: "1.5", text: "..."}]}

      iex> get_subtitles("https://youtube.com/shorts/dQw4w9WgXcQ")
      {:ok, [%Subtitle{start: "0.0", duration: "1.5", text: "..."}]}
  """
  @spec get_subtitles(String.t(), String.t()) :: {:ok, [Subtitle.t()]} | {:error, String.t()}
  def get_subtitles(video_id_or_url, lang \\ "ru") do
    with {:ok, video_id} <- extract_video_id(video_id_or_url),
         {:ok, %{player_data: player_data, next_data: next_data}} <- fetch_video_info(video_id) do
      fetch_subtitles_with_fallback(video_id, player_data, next_data, lang)
    end
  end

  @doc """
  Extracts video ID from a YouTube URL or returns the ID if already provided.

  Supports the following URL formats:
  - https://www.youtube.com/watch?v={ID}
  - https://youtube.com/shorts/{ID}
  - https://youtu.be/{ID}

  ## Examples

      iex> extract_video_id("dQw4w9WgXcQ")
      {:ok, "dQw4w9WgXcQ"}

      iex> extract_video_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      {:ok, "dQw4w9WgXcQ"}

      iex> extract_video_id("https://youtube.com/shorts/dQw4w9WgXcQ")
      {:ok, "dQw4w9WgXcQ"}

      iex> extract_video_id("https://youtu.be/dQw4w9WgXcQ")
      {:ok, "dQw4w9WgXcQ"}

      iex> extract_video_id("invalid-url")
      {:ok, "invalid-url"}
  """
  @spec extract_video_id(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def extract_video_id(video_id_or_url) do
    cond do
      String.contains?(video_id_or_url, "youtube.com/watch") ->
        extract_from_watch_url(video_id_or_url)

      String.contains?(video_id_or_url, "youtube.com/shorts/") ->
        extract_from_shorts_url(video_id_or_url)

      String.contains?(video_id_or_url, "youtu.be/") ->
        extract_from_short_url(video_id_or_url)

      true ->
        {:ok, video_id_or_url}
    end
  end

  defp extract_from_watch_url(url) do
    with %URI{query: query} when is_binary(query) <- URI.parse(url),
         %{"v" => video_id} <- URI.decode_query(query) do
      {:ok, video_id}
    else
      %URI{} -> {:error, "Invalid YouTube URL"}
      _other -> {:error, "Could not extract video ID from URL"}
    end
  end

  defp extract_from_shorts_url(url) do
    video_id =
      url
      |> String.split("/shorts/")
      |> List.last()
      |> String.split("?")
      |> List.first()

    {:ok, video_id}
  end

  defp extract_from_short_url(url) do
    video_id =
      url
      |> String.split("youtu.be/")
      |> List.last()
      |> String.split("?")
      |> List.first()

    {:ok, video_id}
  end

  ## Private Functions

  defp generate_visitor_data do
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    char_list = String.graphemes(chars)

    Enum.map_join(1..11, fn _idx -> Enum.random(char_list) end)
  end

  defp generate_session_data do
    visitor_data = generate_visitor_data()

    %{
      context: %{
        client: %{
          hl: "en",
          gl: "US",
          clientName: @client_config.web.name,
          clientVersion: @client_config.web.version,
          visitorData: visitor_data
        },
        user: %{
          enableSafetyMode: false
        },
        request: %{
          useSsl: true
        }
      },
      visitorData: visitor_data
    }
  end

  defp fetch_innertube(endpoint, payload) do
    Logger.debug("Calling InnerTube endpoint: #{endpoint}")
    Client.fetch_innertube(endpoint, payload, payload.visitorData)
  end

  defp fetch_video_info(video_id) do
    session_data = generate_session_data()

    payload =
      Map.merge(session_data, %{
        videoId: video_id,
        playbackContext: %{
          contentPlaybackContext: %{
            vis: 0,
            splay: false,
            lactMilliseconds: "-1"
          }
        },
        racyCheckOk: true,
        contentCheckOk: true
      })

    with {:ok, player_data} <- fetch_innertube("/player", payload) do
      if get_in(player_data, ["playabilityStatus", "status"]) == "LOGIN_REQUIRED" do
        Logger.debug("LOGIN_REQUIRED status, trying next endpoint")

        next_payload = Map.put(session_data, :videoId, video_id)

        case fetch_innertube("/next", next_payload) do
          {:ok, next_data} ->
            {:ok, %{player_data: player_data, next_data: next_data}}

          error ->
            error
        end
      else
        {:ok, %{player_data: player_data, next_data: nil}}
      end
    end
  end

  defp extract_title(player_data, next_data) do
    title =
      get_in(player_data, ["videoDetails", "title"]) ||
        get_in(next_data, [
          "contents",
          "twoColumnWatchNextResults",
          "results",
          "results",
          "contents",
          Access.at(0),
          "videoPrimaryInfoRenderer",
          "title",
          "runs",
          Access.at(0),
          "text"
        ]) ||
        get_in(next_data, ["metadata", "videoMetadataRenderer", "title", "simpleText"]) ||
        get_in(next_data, ["videoDetails", "title"]) ||
        "No title found"

    {:ok, title}
  end

  defp extract_description(player_data, next_data) do
    description =
      get_in(player_data, ["videoDetails", "shortDescription"]) ||
        extract_description_from_contents(next_data) ||
        extract_description_from_panels(next_data) ||
        "No description found"

    {:ok, description}
  end

  defp extract_description_from_contents(nil), do: nil

  defp extract_description_from_contents(next_data) do
    case get_in(next_data, ["contents", "twoColumnWatchNextResults", "results", "results", "contents"]) do
      contents when is_list(contents) ->
        Enum.find_value(contents, &extract_description_from_content/1)

      _other ->
        nil
    end
  end

  defp extract_description_from_content(content) do
    case get_in(content, ["videoSecondaryInfoRenderer", "description", "runs"]) do
      runs when is_list(runs) ->
        Enum.map_join(runs, &Map.get(&1, "text", ""))

      _other ->
        get_in(content, ["videoSecondaryInfoRenderer", "attributedDescription", "content"])
    end
  end

  defp extract_description_from_panels(nil), do: nil

  defp extract_description_from_panels(next_data) do
    case get_in(next_data, ["engagementPanels"]) do
      panels when is_list(panels) ->
        Enum.find_value(panels, &extract_description_from_panel/1)

      _other ->
        nil
    end
  end

  defp extract_description_from_panel(panel) do
    items =
      get_in(panel, [
        "engagementPanelSectionListRenderer",
        "content",
        "structuredDescriptionContentRenderer",
        "items"
      ])

    case items do
      items when is_list(items) ->
        Enum.find_value(items, &extract_description_from_item/1)

      _other ->
        nil
    end
  end

  defp extract_description_from_item(item) do
    extract_header_description(item) || extract_body_description(item)
  end

  defp extract_header_description(item) do
    case get_in(item, ["videoDescriptionHeaderRenderer", "description", "runs"]) do
      runs when is_list(runs) -> Enum.map_join(runs, &Map.get(&1, "text", ""))
      _other -> nil
    end
  end

  defp extract_body_description(item) do
    case get_in(item, [
           "expandableVideoDescriptionBodyRenderer",
           "descriptionBodyText",
           "runs"
         ]) do
      runs when is_list(runs) -> Enum.map_join(runs, &Map.get(&1, "text", ""))
      _other -> nil
    end
  end

  defp fetch_subtitles_with_fallback(video_id, player_data, next_data, lang) do
    with {:error, _reason} <- fetch_transcript_from_engagement_panel(video_id, next_data, lang) do
      fetch_subtitles_from_captions(video_id, player_data, lang)
    end
  end

  defp fetch_transcript_from_engagement_panel(_video_id, nil, _lang) do
    {:error, "No next data available"}
  end

  defp fetch_transcript_from_engagement_panel(_video_id, next_data, lang) do
    with {:ok, panel} <- find_transcript_panel(next_data),
         {:ok, token} <- extract_continuation_token(panel, lang),
         {:ok, subtitles} <- fetch_transcript_with_token(token) do
      Logger.debug("Successfully got #{length(subtitles)} subtitles from transcript API")
      {:ok, subtitles}
    else
      {:error, reason} ->
        Logger.debug("Transcript API failed: #{reason}")
        {:error, reason}
    end
  end

  defp find_transcript_panel(next_data) do
    panels = get_in(next_data, ["engagementPanels"]) || []

    panel =
      Enum.find(panels, fn panel ->
        get_in(panel, ["engagementPanelSectionListRenderer", "panelIdentifier"]) ==
          "engagement-panel-searchable-transcript"
      end)

    if panel, do: {:ok, panel}, else: {:error, "No transcript engagement panel found"}
  end

  defp extract_continuation_token(panel, lang) do
    content = get_in(panel, ["engagementPanelSectionListRenderer", "content"])

    token =
      get_in(content, [
        "continuationItemRenderer",
        "continuationEndpoint",
        "continuationCommand",
        "token"
      ]) ||
        get_in(content, [
          "continuationItemRenderer",
          "continuationEndpoint",
          "getTranscriptEndpoint",
          "params"
        ]) ||
        extract_token_from_section_list(content) ||
        extract_token_from_transcript_renderer(content, lang)

    if token, do: {:ok, token}, else: {:error, "No continuation token found"}
  end

  defp extract_token_from_section_list(content) do
    case get_in(content, ["sectionListRenderer", "contents", Access.at(0)]) do
      nil ->
        nil

      item ->
        get_in(item, [
          "continuationItemRenderer",
          "continuationEndpoint",
          "continuationCommand",
          "token"
        ])
    end
  end

  defp extract_token_from_transcript_renderer(content, lang) do
    contents = get_in(content, ["sectionListRenderer", "contents"]) || []
    lang_name = language_name(lang)

    Enum.find_value(contents, &extract_token_from_transcript_item(&1, lang_name))
  end

  defp extract_token_from_transcript_item(item, lang_name) do
    menu_items =
      get_in(item, [
        "transcriptRenderer",
        "footer",
        "transcriptFooterRenderer",
        "languageMenu",
        "sortFilterSubMenuRenderer",
        "subMenuItems"
      ])

    case menu_items do
      menu_items when is_list(menu_items) ->
        lang_item = find_language_item(menu_items, lang_name)
        get_in(lang_item, ["continuation", "reloadContinuationData", "continuation"])

      _other ->
        nil
    end
  end

  defp find_language_item(menu_items, lang_name) do
    Enum.find(menu_items, &language_matches?(&1, lang_name)) || List.first(menu_items)
  end

  defp language_matches?(menu_item, lang_name) do
    title = get_in(menu_item, ["title"]) || ""

    title_matches =
      title
      |> String.downcase()
      |> String.contains?(lang_name)

    title_matches || menu_item["selected"] == true
  end

  defp language_name("ru"), do: "russian"
  defp language_name("en"), do: "english"
  defp language_name(lang), do: lang

  defp fetch_transcript_with_token(token) do
    session_data = generate_session_data()
    payload = Map.put(session_data, :params, token)

    with {:ok, data} <- fetch_innertube("/get_transcript", payload) do
      parse_transcript_segments(data)
    end
  end

  defp parse_transcript_segments(data) do
    segments =
      get_in(data, [
        "actions",
        Access.at(0),
        "updateEngagementPanelAction",
        "content",
        "transcriptRenderer",
        "content",
        "transcriptSearchPanelRenderer",
        "body",
        "transcriptSegmentListRenderer",
        "initialSegments"
      ])

    if segments && is_list(segments) do
      subtitles =
        segments
        |> Enum.map(&parse_transcript_segment/1)
        |> Enum.reject(&is_nil/1)

      {:ok, subtitles}
    else
      {:error, "No transcript segments found"}
    end
  end

  defp parse_transcript_segment(%{"transcriptSegmentRenderer" => renderer}) do
    start_ms = String.to_integer(renderer["startMs"] || "0")
    end_ms = String.to_integer(renderer["endMs"] || "0")

    text =
      case renderer["snippet"] do
        %{"simpleText" => simple_text} -> simple_text
        %{"runs" => runs} when is_list(runs) -> Enum.map_join(runs, &Map.get(&1, "text", ""))
        %{"text" => text} -> text
        _other -> ""
      end

    decoded_text = decode_html_entities(text)

    if String.trim(decoded_text) != "" do
      %Subtitle{
        start: Float.to_string(start_ms / 1000),
        duration: Float.to_string((end_ms - start_ms) / 1000),
        text: decoded_text
      }
    end
  end

  defp parse_transcript_segment(_segment), do: nil

  defp fetch_subtitles_from_captions(video_id, player_data, lang) do
    caption_tracks = get_in(player_data, ["captions", "playerCaptionsTracklistRenderer", "captionTracks"])

    if caption_tracks && is_list(caption_tracks) do
      subtitle =
        Enum.find(caption_tracks, fn track -> track["vssId"] == ".#{lang}" end) ||
          Enum.find(caption_tracks, fn track -> track["vssId"] == "a.#{lang}" end) ||
          Enum.find(caption_tracks, fn track ->
            String.contains?(track["vssId"] || "", ".#{lang}")
          end) ||
          List.first(caption_tracks)

      case subtitle do
        %{"baseUrl" => base_url} ->
          caption_url = String.replace(base_url, "&fmt=srv3", "")
          fetch_and_parse_captions(caption_url, video_id)

        _other ->
          {:error, "No suitable caption track found"}
      end
    else
      {:error, "No caption tracks found"}
    end
  end

  defp fetch_and_parse_captions(caption_url, video_id) do
    case Client.fetch_captions(caption_url, video_id) do
      {:ok, xml_text} ->
        {:ok, parse_xml_captions(xml_text)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_xml_captions(xml_text) do
    xml_text
    |> String.replace(~r/^<\?xml.*?\?><transcript>/, "")
    |> String.replace("</transcript>", "")
    |> String.split("</text>")
    |> Enum.map(&parse_xml_caption_line/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_xml_caption_line(line) do
    line = String.trim(line)

    if line != "" do
      with {:ok, start} <- extract_xml_attribute(line, "start"),
           {:ok, duration} <- extract_xml_attribute(line, "dur") do
        text =
          line
          |> String.replace(~r/<text[^>]+>/, "")
          |> String.replace("&amp;", "&")
          |> String.replace(~r/<\/?[^>]+(>|$)/, "")
          |> decode_html_entities()

        %Subtitle{start: start, duration: duration, text: text}
      else
        _error -> nil
      end
    end
  end

  defp extract_xml_attribute(line, attr) do
    case Regex.run(~r/#{attr}="([\d.]+)"/, line) do
      [_full_match, value] -> {:ok, value}
      _no_match -> :error
    end
  end

  defp decode_html_entities(text) do
    text
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&amp;", "&")
    |> decode_numeric_entities()
  end

  defp decode_numeric_entities(text) do
    Regex.replace(~r/&#(\d+);/, text, fn _full_match, code ->
      code
      |> String.to_integer()
      |> List.wrap()
      |> List.to_string()
    end)
  end
end
