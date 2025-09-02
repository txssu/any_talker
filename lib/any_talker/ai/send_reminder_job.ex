defmodule AnyTalker.AI.SendReminderJob do
  @moduledoc false
  use Oban.Worker, queue: :default

  alias AnyTalker.Accounts
  alias AnyTalkerBot.MarkdownUtils

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message" => message, "chat_id" => chat_id, "user_id" => user_id}}) do
    username =
      user_id
      |> Accounts.get_user()
      |> Accounts.display_name()

    text = add_mention(message, user_id, username)

    ExGram.send_message!(chat_id, text, parse_mode: "MarkdownV2", bot: AnyTalkerBot.bot())

    :ok
  end

  defp add_mention(text, user_id, username) do
    """
    [#{username}](tg://user?id=#{user_id}), #{MarkdownUtils.escape_markdown(text)}
    """
  end
end
