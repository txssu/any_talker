defmodule JokerCynicBot.NikitaCounterAnswerHandler do
  @moduledoc false
  use JokerCynicBot, :command

  import JokerCynic.Counters.Helpers

  alias JokerCynicBot.Reply

  @impl JokerCynicBot.Command
  def call(%Reply{message: {:callback_query, callback_query}} = reply) do
    if callback_query.from.id == 562_754_575 do
      message = callback_query.message

      answer_counter(message.chat.id, message.message_id, "#{message.text}\nОтвет дан.", answer(callback_query.data))
    end

    %Reply{reply | halt: true}
  end

  defp answer("counter-yes") do
    "Никита, зачем ты ответил, что у тебя был секс? Ты хотя бы себя не обманывай.\n#{nikita_counter()}"
  end

  defp answer("counter-no") do
    "Никита. #{nikita_counter()}"
  end
end
