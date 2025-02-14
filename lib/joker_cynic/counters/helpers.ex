defmodule JokerCynic.Counters.Helpers do
  @moduledoc false
  @spec nikita_counter() :: String.t()
  def nikita_counter do
    days = Date.diff(Date.utc_today(), ~D[2005-02-10])

    "День без секса #{days}."
  end

  @spec answer_counter(integer(), integer(), String.t(), String.t()) :: :ok
  def answer_counter(chat_id, message_id, new_confirmation_text, new_message_text) do
    ExGram.edit_message_text(new_confirmation_text,
      chat_id: chat_id,
      message_id: message_id,
      bot: JokerCynicBot.Dispatcher.bot()
    )

    ExGram.send_message(chat_id, new_message_text, bot: JokerCynicBot.Dispatcher.bot())

    :ok
  end
end
