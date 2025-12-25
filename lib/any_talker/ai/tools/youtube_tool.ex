defmodule AnyTalker.AI.YouTubeTool do
  @moduledoc false
  @behaviour AnyTalker.AI.Tool

  alias AnyTalker.AI.Tool.Function
  alias AnyTalker.AI.Tool.FunctionArg
  alias AnyTalker.YouTube.CaptionExtractor
  alias AnyTalker.YouTube.SubtitleFormatter

  require Logger

  def spec do
    %Function{
      name: "youtube",
      description:
        "Extract video details and subtitles from a YouTube video. Returns title, description, and full transcript text in Russian. Pass the full YouTube URL.",
      args: [
        %FunctionArg{
          name: "video_url",
          type: "string",
          description:
            "Full YouTube URL (e.g., 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'https://youtu.be/dQw4w9WgXcQ')"
        }
      ]
    }
  end

  def call(%{"video_url" => video_url}, _context) do
    case CaptionExtractor.get_video_details(video_url, "ru") do
      {:ok, video_details} ->
        transcript_text = SubtitleFormatter.to_text(video_details)

        {:ok,
         %{
           "title" => video_details.title,
           "description" => video_details.description,
           "transcript" => transcript_text
         }}

      {:error, reason} ->
        Logger.error("YouTube extraction failed", details: %{reason: reason})
        {:error, "Видео не существует или информация о нём недоступна."}
    end
  end
end
