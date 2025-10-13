defmodule AnyTalker.YouTube.SubtitleFormatter do
  @moduledoc """
  Formats and transforms subtitle data.

  Provides utilities for converting subtitle lists into various text formats.
  By default, limits output to first 10 minutes of video.

  ## Usage

      {:ok, video_details} = AnyTalker.YouTube.CaptionExtractor.get_video_details("video_id")
      text = AnyTalker.YouTube.SubtitleFormatter.to_text(video_details)

      {:ok, subtitles} = AnyTalker.YouTube.CaptionExtractor.get_subtitles("video_id")
      text = AnyTalker.YouTube.SubtitleFormatter.to_text(subtitles)
  """

  alias AnyTalker.YouTube.CaptionExtractor.Subtitle
  alias AnyTalker.YouTube.CaptionExtractor.VideoDetails

  @max_duration_seconds 600

  @doc """
  Joins all subtitles into a single text string.

  Only includes subtitles from the first 10 minutes (600 seconds) of the video.

  ## Parameters

    * `input` - VideoDetails struct or list of Subtitle structs
    * `separator` - String to use between subtitles (default: " ")

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
      iex> SubtitleFormatter.to_text(subtitles, "\\n")
      "Hello\\nworld"
  """
  @spec to_text(VideoDetails.t() | [Subtitle.t()], String.t()) :: String.t()
  def to_text(input, separator \\ " ")

  def to_text(%VideoDetails{subtitles: subtitles}, separator) do
    to_text(subtitles, separator)
  end

  def to_text([], _separator), do: ""

  def to_text(subtitles, separator) when is_list(subtitles) do
    subtitles
    |> filter_by_duration()
    |> Enum.map_join(separator, & &1.text)
  end

  defp filter_by_duration(subtitles) do
    Enum.take_while(subtitles, fn subtitle ->
      case Float.parse(subtitle.start) do
        {start_time, _rest} -> start_time < @max_duration_seconds
        :error -> true
      end
    end)
  end
end
