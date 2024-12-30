defmodule JokerCynic.Antispam.KickUserJob do
  @moduledoc false
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "chat_id" => chat_id}}) do
    # Check if captcha is still relevant
    if JokerCynic.Antispam.get_captcha(user_id, chat_id) do
      ExGram.ban_chat_member!(chat_id, user_id, bot: JokerCynicBot.Dispatcher.bot())
    end

    :ok
  end
end
