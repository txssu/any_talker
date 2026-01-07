defmodule AnyTalker.AI.CreateTaskAtTool do
  @moduledoc false
  @behaviour AnyTalker.AI.Tool

  alias AnyTalker.AI.FunctionContext
  alias AnyTalker.AI.Tool.Function
  alias AnyTalker.AI.Tool.FunctionArg
  alias AnyTalker.Reminders

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
          description: "ISO 8601 datetime when the reminder should be sent"
        }
      ]
    }
  end

  def call(%{"message" => message, "reminder_at" => reminder_at_str}, %FunctionContext{} = ctx) do
    with {:ok, reminder_at} <- parse_datetime(reminder_at_str),
         delay_seconds = DateTime.diff(reminder_at, DateTime.utc_now()),
         :ok <- validate_minimum_delay(delay_seconds) do
      attrs = %{
        message: message,
        chat_id: ctx.chat.id,
        user_id: ctx.user.id,
        reply_to_id: ctx.message.message_id,
        scheduled_at: reminder_at
      }

      case Reminders.create_reminder(attrs) do
        {:ok, _reminder} -> {:ok, "ok"}
        {:error, _changeset} -> {:error, "Failed to create reminder"}
      end
    end
  end

  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, reminder_at, _offset} -> {:ok, reminder_at}
      {:error, reason} -> {:error, "Invalid reminder_at format: #{reason}"}
    end
  end

  defp validate_minimum_delay(delay) when delay < 60 do
    {:error, "Reminder must be scheduled at least 1 minute in the future"}
  end

  defp validate_minimum_delay(_delay), do: :ok
end
