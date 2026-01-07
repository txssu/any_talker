defmodule AnyTalker.AI.CreateTaskAfterTool do
  @moduledoc false
  @behaviour AnyTalker.AI.Tool

  alias AnyTalker.AI.FunctionContext
  alias AnyTalker.AI.Tool.Function
  alias AnyTalker.AI.Tool.FunctionArg
  alias AnyTalker.Reminders

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

    with :ok <- validate_minimum_delay(total_minutes) do
      scheduled_at = DateTime.add(DateTime.utc_now(), total_minutes * 60, :second)

      attrs = %{
        message: message,
        chat_id: ctx.chat.id,
        user_id: ctx.user.id,
        reply_to_id: ctx.message.message_id,
        scheduled_at: scheduled_at
      }

      case Reminders.create_reminder(attrs) do
        {:ok, _reminder} -> {:ok, "ok"}
        {:error, _changeset} -> {:error, "Failed to create reminder"}
      end
    end
  end

  defp validate_minimum_delay(delay) when delay < 1 do
    {:error, "Reminder must be scheduled at least 1 minute in the future"}
  end

  defp validate_minimum_delay(_delay), do: :ok
end
