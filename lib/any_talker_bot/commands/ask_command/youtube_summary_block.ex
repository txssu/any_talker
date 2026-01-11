defmodule AnyTalkerBot.AskCommand.YouTubeSummaryBlock do
  @moduledoc false
  @behaviour AnyTalkerBot.AskCommand.ResponseBlock

  alias AnyTalker.Accounts.Subscription
  alias AnyTalker.Accounts.User
  alias AnyTalker.AI.Generation
  alias AnyTalker.AI.Tool.CallResult
  alias AnyTalker.AI.YouTubeTool
  alias AnyTalkerBot.HtmlUtils

  @impl AnyTalkerBot.AskCommand.ResponseBlock
  def extract(%Generation{} = gen, %User{} = user) do
    if Subscription.active_pro?(user.current_subscription) do
      gen
      |> extract_summaries()
      |> format_blockquotes()
    end
  end

  defp extract_summaries(%Generation{} = gen) do
    gen
    |> Generation.call_results()
    |> Enum.filter(&match?(%CallResult{module: YouTubeTool, success: true}, &1))
    |> Enum.flat_map(fn %CallResult{value: value} ->
      case value do
        %{"transcript_summary" => summary} -> [summary]
        _no_summary -> []
      end
    end)
  end

  defp format_blockquotes([]), do: nil

  defp format_blockquotes(summaries) do
    Enum.map_join(summaries, "\n\n", fn summary ->
      "<blockquote expandable>#{HtmlUtils.escape_html_preserving_tags(summary)}</blockquote>"
    end)
  end
end
