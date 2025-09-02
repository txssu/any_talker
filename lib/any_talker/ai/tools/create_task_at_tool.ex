defmodule AnyTalker.AI.CreateTaskAtTool do
  @moduledoc false
  use AnyTalker.AI.Tool, type: :function

  alias AnyTalker.AI.Function
  alias AnyTalker.AI.SendReminderJob
  alias AnyTalker.AI.Tool

  @impl Tool
  def spec do
    %{
      type: "function",
      name: name(),
      description: "Creates a task reminder that will be sent at a specific time",
      strict: true,
      parameters: %{
        type: "object",
        additionalProperties: false,
        properties: %{
          message: %{
            type: "string",
            description: """
            The message that will be sent to the user as a reminder from the AI assistant.
            Write it as if you (the AI) are speaking directly to the user.
            The user's name will be automatically added as a mention at the beginning.
            DO NOT repeat this message to the user in your response - it will be sent automatically at the scheduled time.
            Example: 'напоминаю тебе позвонить маме' will become '@username, напоминаю тебе позвонить маме'
            """
          },
          reminder_at: %{
            type: "string",
            description: "ISO 8601 datetime when the reminder should be sent",
            format: "date-time"
          }
        },
        required: ["message", "reminder_at"]
      }
    }
  end

  @impl Function
  def name, do: "create_task_at"

  @impl Function
  def exec(params, %{chat_id: chat_id, user_id: user_id}) do
    with {:ok, reminder_at} <- parse_datetime(params["reminder_at"]),
         delay_seconds = DateTime.diff(reminder_at, DateTime.utc_now(), :second),
         :ok <- validate_minimum_delay(delay_seconds * 1000) do
      %{
        "message" => params["message"],
        "chat_id" => chat_id,
        "user_id" => user_id
      }
      |> SendReminderJob.new(scheduled_at: reminder_at)
      |> Oban.insert()

      "ok"
    else
      {:error, reason} -> %{"error" => "Invalid reminder_at format: #{reason}"}
    end
  end

  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, reminder_at, _offset} -> {:ok, reminder_at}
      {:error, reason} -> {:error, "Invalid reminder_at format: #{reason}"}
    end
  end

  defp validate_minimum_delay(delay) do
    if delay < 60_000 do
      {:error, "Reminder must be scheduled at least 1 minute in the future"}
    else
      :ok
    end
  end
end
