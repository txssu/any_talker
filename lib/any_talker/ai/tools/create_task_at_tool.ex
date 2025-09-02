defmodule AnyTalker.AI.CreateTaskAtTool do
  @moduledoc false
  use AnyTalker.AI.Tool, type: :function

  alias AnyTalker.Accounts
  alias AnyTalker.AI.Function
  alias AnyTalker.AI.Tool
  alias AnyTalkerBot.MarkdownUtils

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
    with {:ok, reminder_at, _offset} <- DateTime.from_iso8601(params["reminder_at"]),
         delay = DateTime.diff(reminder_at, DateTime.utc_now(), :millisecond),
         :ok <- validate_minimum_delay(delay) do
      username =
        user_id
        |> Accounts.get_user()
        |> Accounts.display_name()

      text =
        params
        |> Map.fetch!("message")
        |> add_mention(user_id, username)

      :timer.apply_after(delay, fn ->
        ExGram.send_message!(chat_id, text, parse_mode: "MarkdownV2", bot: AnyTalkerBot.bot())
      end)

      :ok
    else
      {:error, reason} -> {:error, "Invalid reminder_at format: #{reason}"}
    end
  end

  defp add_mention(text, user_id, username) do
    """
    [#{username}](tg://user?id=#{user_id}), #{MarkdownUtils.escape_markdown(text)}
    """
  end

  defp validate_minimum_delay(delay) do
    if delay < 60_000 do
      {:error, "Reminder must be scheduled at least 1 minute in the future"}
    else
      :ok
    end
  end
end
