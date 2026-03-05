defmodule AnyTalker.AI.CreateTaskAfterTool do
  @moduledoc false
  @behaviour AnyTalker.AI.Tool

  alias AnyTalker.AI.FunctionContext
  alias AnyTalker.AI.Tool.Function
  alias AnyTalker.AI.Tool.FunctionArg
  alias AnyTalker.Reminders.AITool

  def spec do
    %Function{
      name: "create_task_after",
      description: "Creates a task reminder that will be sent after a specific duration from now",
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
          name: "hours",
          type: "integer",
          description: "Number of hours to wait before sending the reminder",
          minimum: 0
        },
        %FunctionArg{
          name: "minutes",
          type: "integer",
          description: "Number of minutes to wait before sending the reminder",
          minimum: 0
        }
      ]
    }
  end

  def call(%{"message" => message, "hours" => hours, "minutes" => minutes}, %FunctionContext{} = ctx) do
    total_minutes = hours * 60 + minutes

    with :ok <- AITool.validate_minimum_delay_minutes(total_minutes) do
      scheduled_at = DateTime.add(DateTime.utc_now(), total_minutes * 60, :second)
      AITool.create_reminder(%{message: message, scheduled_at: scheduled_at, ctx: ctx})
    end
  end
end
