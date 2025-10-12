defmodule AnyTalker.AI.SendReminderJob do
  @moduledoc false
  use Oban.Worker, queue: :default

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.User
  alias AnyTalker.Reminders
  alias AnyTalker.Reminders.Reminder
  alias AnyTalkerBot.MarkdownUtils

  # New format: load reminder from database
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"reminder_id" => reminder_id}}) do
    reminder = Reminders.get_reminder!(reminder_id)
    send_reminder(reminder)
  end

  # Old format: create reminder struct from args (backward compatibility)
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message" => message, "chat_id" => cid, "user_id" => uid} = args}) do
    reminder = %Reminder{
      message: message,
      chat_id: cid,
      user_id: uid,
      reply_to_id: Map.get(args, "reply_to_id")
    }

    send_reminder(reminder)
  end

  defp send_reminder(%Reminder{} = reminder) do
    text =
      reminder.user_id
      |> Accounts.get_user()
      |> to_text_with_mention(reminder.message)

    base_options = [
      parse_mode: "MarkdownV2",
      bot: AnyTalkerBot.bot()
    ]

    options =
      case reminder.reply_to_id do
        nil -> base_options
        mid -> Keyword.put(base_options, :reply_parameters, reply_parameters(mid, reminder.chat_id))
      end

    ExGram.send_message!(reminder.chat_id, text, options)

    :ok
  end

  defp reply_parameters(message_id, chat_id) do
    %ExGram.Model.ReplyParameters{message_id: message_id, chat_id: chat_id}
  end

  defp to_text_with_mention(%User{} = user, text) do
    username =
      user
      |> Accounts.display_name()
      |> MarkdownUtils.escape_markdown()

    formatted_text = MarkdownUtils.escape_markdown(text)

    """
    [#{username}](tg://user?id=#{user.id}), #{formatted_text}
    """
  end
end
