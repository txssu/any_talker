defmodule AnyTalker.Reminders.AITool do
  @moduledoc false

  alias AnyTalker.Accounts
  alias AnyTalker.AI.FunctionContext
  alias AnyTalker.Reminders
  alias AnyTalker.Timezone

  require Logger

  @dm_error_message "Bot cannot create a reminder in inline mode. Ask the user to open the bot chat and allow the bot to send direct messages so the reminder can be scheduled."

  @doc """
  Creates a reminder with the given attributes after validating and preparing the target.
  """
  def create_reminder(%{message: message, scheduled_at: scheduled_at, ctx: %FunctionContext{} = ctx}) do
    with {:ok, chat_id, reply_to_id} <- prepare_reminder_target(ctx, scheduled_at) do
      attrs = %{
        message: message,
        chat_id: chat_id,
        user_id: ctx.user.id,
        reply_to_id: reply_to_id,
        scheduled_at: scheduled_at
      }

      case Reminders.create_reminder(attrs) do
        {:ok, _reminder} ->
          {:ok, %{"scheduled_at" => scheduled_at}}

        {:error, changeset} ->
          Logger.error("Failed to create reminder",
            details: %{errors: changeset.errors, attrs: Map.delete(attrs, :message)}
          )

          {:error, "Failed to create reminder"}
      end
    end
  end

  @doc """
  Validates that the delay in seconds is at least 60 seconds (1 minute).
  """
  def validate_minimum_delay_seconds(delay) when delay < 60 do
    {:error, "Reminder must be scheduled at least 1 minute in the future"}
  end

  def validate_minimum_delay_seconds(_delay), do: :ok

  @doc """
  Validates that the delay in minutes is at least 1 minute.
  """
  def validate_minimum_delay_minutes(delay) when delay < 1 do
    {:error, "Reminder must be scheduled at least 1 minute in the future"}
  end

  def validate_minimum_delay_minutes(_delay), do: :ok

  @doc """
  Parses an ISO 8601 datetime string.
  """
  def parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, reminder_at, _offset} -> {:ok, reminder_at}
      {:error, reason} -> {:error, "Invalid reminder_at format: #{reason}"}
    end
  end

  # For inline mode (message is nil): send DM confirmation and use DM chat
  defp prepare_reminder_target(%FunctionContext{message: nil} = ctx, scheduled_at) do
    with {:ok, dm_message_id} <- send_dm_confirmation(ctx.user, scheduled_at, ctx.text) do
      {:ok, ctx.user.id, dm_message_id}
    end
  end

  # For DM mode (message exists but no chat config): use user id as chat id
  defp prepare_reminder_target(%FunctionContext{chat: %AnyTalker.Settings.ChatConfig{id: nil}} = ctx, _scheduled_at) do
    {:ok, ctx.user.id, ctx.message.message_id}
  end

  # For regular mode: use original chat and message
  defp prepare_reminder_target(%FunctionContext{} = ctx, _scheduled_at) do
    {:ok, ctx.chat.id, ctx.message.message_id}
  end

  defp send_dm_confirmation(user, scheduled_at, original_query) do
    formatted_datetime = format_datetime(scheduled_at, Accounts.get_timezone(user, nil))
    text = "<blockquote>#{escape_html(original_query)}</blockquote>\nБыло создано напоминание на #{formatted_datetime}"

    opts = [
      parse_mode: "HTML",
      bot: AnyTalkerBot.bot()
    ]

    case ExGram.send_message(user.id, text, opts) do
      {:ok, %{message_id: message_id}} ->
        {:ok, message_id}

      {:error, error} ->
        Logger.error("Failed to send DM confirmation",
          details: %{user_id: user.id, error: inspect(error)}
        )

        {:error, @dm_error_message}
    end
  end

  defp escape_html(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp escape_html(nil), do: ""

  defp format_datetime(%DateTime{} = dt, timezone) do
    shifted = DateTime.shift_zone!(dt, timezone)
    offset = Timezone.format_utc_offset(shifted.utc_offset)
    Calendar.strftime(shifted, "%d.%m.%Y в %H:%M (#{offset})")
  end
end
