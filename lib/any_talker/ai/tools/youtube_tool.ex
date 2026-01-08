defmodule AnyTalker.AI.YouTubeTool do
  @moduledoc false
  @behaviour AnyTalker.AI.Tool

  alias AnyTalker.Accounts.Subscription
  alias AnyTalker.Accounts.User
  alias AnyTalker.AI.FunctionContext
  alias AnyTalker.AI.Summarizer
  alias AnyTalker.AI.Tool.Function
  alias AnyTalker.AI.Tool.FunctionArg
  alias AnyTalker.YouTube.CaptionExtractor
  alias AnyTalker.YouTube.SubtitleFormatter

  require Logger

  @max_transcript_length 1500
  @max_duration_free 600
  @max_duration_pro 2400

  def spec do
    %Function{
      name: "youtube",
      description:
        "Extract video details and subtitles from a YouTube video. Returns title, description, and transcript (or summary for long videos). Pass the full YouTube URL.",
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

  def call(%{"video_url" => video_url}, context) do
    case CaptionExtractor.get_video_details(video_url, "ru") do
      {:ok, video_details} ->
        {:ok, build_result(video_details, context)}

      {:error, reason} ->
        Logger.error("YouTube extraction failed", details: %{reason: reason})
        {:error, "Видео не существует или информация о нём недоступна."}
    end
  end

  defp build_result(video_details, context) do
    video_details
    |> base_result()
    |> add_transcript_data(video_details, has_pro_subscription?(context))
  end

  defp has_pro_subscription?(%FunctionContext{user: %User{current_subscription: subscription}}) do
    Subscription.active_pro?(subscription)
  end

  defp has_pro_subscription?(_context), do: false

  defp base_result(video_details) do
    %{
      "title" => video_details.title,
      "description" => video_details.description
    }
  end

  defp add_transcript_data(result, %{transcript_error: error}, _has_pro) when is_binary(error) do
    Map.put(result, "transcript_error", "Не удалось получить транскрипцию: #{error}")
  end

  defp add_transcript_data(result, video_details, has_pro) do
    max_duration = if has_pro, do: @max_duration_pro, else: @max_duration_free
    transcript_text = SubtitleFormatter.to_text(video_details, max_duration: max_duration)
    transcript_length = String.length(transcript_text)

    Logger.debug("Transcript extracted",
      details: %{length: transcript_length, max_length: @max_transcript_length, has_pro: has_pro}
    )

    if transcript_length > @max_transcript_length do
      add_summarized_transcript(result, transcript_text)
    else
      Map.put(result, "transcript", transcript_text)
    end
  end

  defp add_summarized_transcript(result, transcript_text) do
    Logger.debug("Summarizing transcript", details: %{input_length: String.length(transcript_text)})

    case Summarizer.summarize(transcript_text) do
      {:ok, summary} ->
        Logger.debug("Summarization succeeded", details: %{summary_length: String.length(summary)})
        Map.put(result, "transcript_summary", summary)

      {:error, reason} ->
        Logger.warning("Summarization failed, returning full transcript", details: %{reason: reason})
        Map.put(result, "transcript", transcript_text)
    end
  end
end
