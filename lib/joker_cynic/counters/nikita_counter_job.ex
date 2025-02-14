defmodule JokerCynic.Counters.NikitaCounterJob do
  @moduledoc false
  use Oban.Worker, queue: :default

  import ExGram.Dsl.Keyboard

  alias JokerCynic.Counters.CounterVerificationTimeoutJob

  require ExGram.Dsl.Keyboard

  @impl Oban.Worker
  def perform(_job) do
    markup =
      keyboard :inline do
        row do
          button("Да", callback_data: "counter-yes")
          button("Нет", callback_data: "counter-no")
        end
      end

    message =
      ExGram.send_message!(-1_002_295_394_555, "[Никита](tg://user?id=#{632_365_722}), ты сегодня занялся сексом?",
        reply_markup: markup,
        parse_mode: "MarkdownV2",
        bot: JokerCynicBot.Dispatcher.bot()
      )

    timeout_at = DateTime.add(DateTime.utc_now(), 30, :minute)

    %{text: message.text, chat_id: message.chat.id, message_id: message.message_id}
    |> CounterVerificationTimeoutJob.new(scheduled_at: timeout_at)
    |> Oban.insert()

    :ok
  end
end
