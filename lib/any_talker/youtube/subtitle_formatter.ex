defmodule AnyTalker.YouTube.SubtitleFormatter do
  @moduledoc """
  Formats and transforms subtitle data.

  Provides utilities for converting subtitle lists into various text formats.
  By default, limits output to first 10 minutes of video.

  ## Usage

      {:ok, video_details} = AnyTalker.YouTube.YtExtractor.get_video_details("video_id")
      text = AnyTalker.YouTube.SubtitleFormatter.to_text(video_details)

      {:ok, subtitles} = AnyTalker.YouTube.YtExtractor.get_subtitles("video_id")
      text = AnyTalker.YouTube.SubtitleFormatter.to_text(subtitles)
  """

  alias AnyTalker.YouTube.YtExtractor.VideoDetails

  @default_max_duration_seconds 600

  @doc """
  Joins all subtitles into a single text string.

  By default, only includes subtitles from the first 10 minutes (600 seconds).

  ## Parameters

    * `input` - VideoDetails struct or list of Subtitle structs
    * `opts` - Options:
      * `:separator` - String to use between subtitles (default: " ")
      * `:max_duration` - Maximum duration in seconds (default: 600)

  ## Examples

      iex> video_details = %VideoDetails{
      ...>   title: "Video",
      ...>   description: "Desc",
      ...>   subtitles: [
      ...>     %Subtitle{start: "0.0", duration: "1.5", text: "Hello"},
      ...>     %Subtitle{start: "1.5", duration: "1.0", text: "world"}
      ...>   ]
      ...> }
      iex> SubtitleFormatter.to_text(video_details)
      "Hello world"

      iex> subtitles = [
      ...>   %Subtitle{start: "0.0", duration: "1.5", text: "Hello"},
      ...>   %Subtitle{start: "1.5", duration: "1.0", text: "world"}
      ...> ]
      iex> SubtitleFormatter.to_text(subtitles, separator: "\\n")
      "Hello\\nworld"

      iex> SubtitleFormatter.to_text(subtitles, max_duration: 2400)
      "Hello world"
  """
  def to_text(input, opts \\ [])

  def to_text(%VideoDetails{subtitles: subtitles}, opts) do
    to_text(subtitles, opts)
  end

  def to_text([], _opts), do: ""

  def to_text(subtitles, opts) when is_list(subtitles) do
    separator = Keyword.get(opts, :separator, " ")
    max_duration = Keyword.get(opts, :max_duration, @default_max_duration_seconds)

    subtitles
    |> filter_by_duration(max_duration)
    |> Enum.map_join(separator, & &1.text)
  end

  defp filter_by_duration(subtitles, max_duration) do
    Enum.take_while(subtitles, fn subtitle ->
      case Float.parse(subtitle.start) do
        {start_time, _rest} -> start_time < max_duration
        :error -> true
      end
    end)
  end
end
