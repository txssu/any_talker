defmodule AnyTalker.AI.SendReminderJob do
  @moduledoc false
  use Oban.Worker, queue: :default

  alias AnyTalker.Accounts
  alias AnyTalker.Accounts.User
  alias AnyTalkerBot.MarkdownUtils

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"message" => message, "chat_id" => cid, "user_id" => uid} = args}) do
    text =
      uid
      |> Accounts.get_user()
      |> to_text_with_mention(message)

    base_options = [
      parse_mode: "MarkdownV2",
      bot: AnyTalkerBot.bot()
    ]

    options =
      case Map.get(args, "reply_to_id") do
        nil -> base_options
        mid -> Keyword.put(base_options, :reply_parameters, reply_parameters(mid, cid))
      end

    ExGram.send_message!(cid, text, options)

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
