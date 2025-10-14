defmodule AnyTalker.AI.YouTubeTool do
  @moduledoc false
  use AnyTalker.AI.Tool, type: :function

  alias AnyTalker.AI.Function
  alias AnyTalker.AI.Tool
  alias AnyTalker.YouTube.CaptionExtractor
  alias AnyTalker.YouTube.SubtitleFormatter

  require Logger

  @impl Tool
  def spec do
    %{
      type: "function",
      name: name(),
      description:
        "Extract video details and subtitles from a YouTube video. Returns title, description, and full transcript text in Russian. Pass the full YouTube URL.",
      strict: true,
      parameters: %{
        additionalProperties: false,
        type: "object",
        properties: %{
          video_url: %{
            type: "string",
            description:
              "Full YouTube URL (e.g., 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'https://youtu.be/dQw4w9WgXcQ')"
          }
        },
        required: ["video_url"]
      }
    }
  end

  @impl Function
  def name, do: "youtube"

  @impl Function
  def exec(%{"video_url" => video_url}, _context) do
    case CaptionExtractor.get_video_details(video_url, "ru") do
      {:ok, video_details} ->
        transcript_text = SubtitleFormatter.to_text(video_details)

        %{
          "title" => video_details.title,
          "description" => video_details.description,
          "transcript" => transcript_text
        }

      {:error, reason} ->
        Logger.error("YouTube extraction failed", details: %{reason: reason})
        "Не удалось извлечь субтитры: #{reason}"
    end
  end
end
