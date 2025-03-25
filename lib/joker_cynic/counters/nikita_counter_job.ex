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

    text = "[Никита](tg://user?id=#{562_754_575}), ты сегодня занялся сексом?"

    message =
      ExGram.send_message!(-1_001_549_164_880, text,
        reply_markup: markup,
        parse_mode: "MarkdownV2",
        bot: JokerCynicBot.Dispatcher.bot()
      )

    timeout_at = DateTime.add(DateTime.utc_now(), 30, :minute)

    %{text: text, chat_id: message.chat.id, message_id: message.message_id}
    |> CounterVerificationTimeoutJob.new(scheduled_at: timeout_at)
    |> Oban.insert()

    :ok
  end
end
