defmodule AnyTalkerBot.AskCommand.ReminderBlock do
  @moduledoc false
  @behaviour AnyTalkerBot.AskCommand.ResponseBlock

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.User
  alias AnyTalker.AI.CreateTaskAfterTool
  alias AnyTalker.AI.CreateTaskAtTool
  alias AnyTalker.AI.FunctionContext
  alias AnyTalker.AI.Generation
  alias AnyTalker.AI.Request
  alias AnyTalker.AI.Tool.CallResult
  alias AnyTalker.Timezone
  alias AnyTalker.TypedStructAccess

  require TypedStructAccess

  @impl AnyTalkerBot.AskCommand.ResponseBlock
  def extract(%Generation{} = gen, %User{} = user) do
    chat = TypedStructAccess.get(gen.request.function_context.chat, [Request, FunctionContext])
    timezone = Accounts.get_timezone(user, chat)

    gen
    |> extract_reminder_times()
    |> format_blockquotes(timezone)
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

  defp format_blockquotes([], _timezone), do: nil

  defp format_blockquotes(reminders, timezone) do
    Enum.map_join(reminders, "\n\n", fn scheduled_at ->
      formatted = format_datetime(scheduled_at, timezone)
      "<blockquote expandable>Было создано напоминание на #{formatted}</blockquote>"
    end)
  end

  defp format_datetime(%DateTime{} = dt, timezone) do
    shifted = DateTime.shift_zone!(dt, timezone)
    offset = Timezone.format_utc_offset(shifted.utc_offset)
    Calendar.strftime(shifted, "%d.%m.%Y в %H:%M (#{offset})")
  end
end
