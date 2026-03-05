defmodule AnyTalker.AI.CreateTaskAtTool do
  @moduledoc false
  @behaviour AnyTalker.AI.Tool

  alias AnyTalker.AI.FunctionContext
  alias AnyTalker.AI.Tool.Function
  alias AnyTalker.AI.Tool.FunctionArg
  alias AnyTalker.Reminders.AITool

  def spec do
    %Function{
      name: "create_task_at",
      description: "Creates a task reminder that will be sent at a specific time",
      args: [
        %FunctionArg{
          name: "message",
          type: "string",
          description: """
          The message that will be sent to the user as a reminder from the AI assistant.
          Write it as if you (the AI) are speaking directly to the user.
          DO NOT repeat this message to the user in your response - it will be sent automatically at the scheduled time.
          """
        },
        %FunctionArg{
          name: "reminder_at",
          type: "string",
          format: "date-time",
          description:
            "ISO 8601 datetime when the reminder should be sent. Note that you must use the user's time zone."
        }
      ]
    }
  end

  def call(%{"message" => message, "reminder_at" => reminder_at_str}, %FunctionContext{} = ctx) do
    with {:ok, reminder_at} <- AITool.parse_datetime(reminder_at_str),
         delay_seconds = DateTime.diff(reminder_at, DateTime.utc_now()),
         :ok <- AITool.validate_minimum_delay_seconds(delay_seconds) do
      AITool.create_reminder(%{message: message, scheduled_at: reminder_at, ctx: ctx})
    end
  end
end
