defmodule AnyTalker.AI.CreateTaskAfterTool do
  @moduledoc false
  use AnyTalker.AI.Tool, type: :function

  alias AnyTalker.AI.Context
  alias AnyTalker.AI.Function
  alias AnyTalker.AI.SendReminderJob
  alias AnyTalker.AI.Tool

  @impl Tool
  def spec do
    %{
      type: "function",
      name: name(),
      description: "Creates a task reminder that will be sent after a specific duration from now",
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
          hours: %{
            type: "integer",
            description: "Number of hours to wait before sending the reminder",
            minimum: 0
          },
          minutes: %{
            type: "integer",
            description: "Number of minutes to wait before sending the reminder",
            minimum: 0
          }
        },
        required: ["message", "hours", "minutes"]
      }
    }
  end

  @impl Function
  def name, do: "create_task_after"

  @impl Function
  def exec(params, %Context{chat_id: cid, user_id: uid, message_id: mid}) do
    hours = params["hours"]
    minutes = params["minutes"]

    total_minutes = hours * 60 + minutes
    delay_milliseconds = total_minutes * 60 * 1000

    case validate_minimum_delay(delay_milliseconds) do
      :ok ->
        scheduled_at = DateTime.add(DateTime.utc_now(), total_minutes * 60, :second)

        %{
          "message" => params["message"],
          "chat_id" => cid,
          "user_id" => uid,
          "reply_to_id" => mid
        }
        |> SendReminderJob.new(scheduled_at: scheduled_at)
        |> Oban.insert()

        "ok"

      {:error, reason} ->
        %{"error" => reason}
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
