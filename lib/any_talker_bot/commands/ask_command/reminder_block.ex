defmodule AnyTalkerBot.AskCommand.ReminderBlock do
  @moduledoc false
  @behaviour AnyTalkerBot.AskCommand.ResponseBlock

  alias AnyTalker.Accounts.User
  alias AnyTalker.AI.CreateTaskAfterTool
  alias AnyTalker.AI.CreateTaskAtTool
  alias AnyTalker.AI.Generation
  alias AnyTalker.AI.Tool.CallResult

  @impl AnyTalkerBot.AskCommand.ResponseBlock
  def extract(%Generation{} = gen, %User{}) do
    gen
    |> extract_reminder_times()
    |> format_blockquotes()
  end

  defp extract_reminder_times(%Generation{} = gen) do
    gen
    |> Generation.call_results()
    |> Enum.filter(fn
      %CallResult{module: CreateTaskAtTool, success: true} -> true
      %CallResult{module: CreateTaskAfterTool, success: true} -> true
      _other -> false
    end)
    |> Enum.flat_map(fn %CallResult{value: value} ->
      case value do
        %{"scheduled_at" => scheduled_at} -> [scheduled_at]
        _no_scheduled_at -> []
      end
    end)
  end

  defp format_blockquotes([]), do: nil

  defp format_blockquotes(reminders) do
    Enum.map_join(reminders, "\n\n", fn scheduled_at ->
      formatted = format_datetime(scheduled_at)
      "<blockquote expandable>Было создано напоминание на #{formatted}</blockquote>"
    end)
  end

  defp format_datetime(%DateTime{} = dt) do
    dt
    |> DateTime.shift_zone!("Asia/Yekaterinburg")
    |> Calendar.strftime("%d.%m.%Y в %H:%M (ЕКБ)")
  end
end
