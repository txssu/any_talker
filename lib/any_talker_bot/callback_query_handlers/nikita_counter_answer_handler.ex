defmodule AnyTalkerBot.NikitaCounterAnswerHandler do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.Counters.Helpers
  alias AnyTalkerBot.Reply

  @impl AnyTalkerBot.Command
  def call(%Reply{message: {:callback_query, callback_query}} = reply) do
    if Helpers.nikita_id?(callback_query.from.id) do
      message = callback_query.message

      answer_type =
        case callback_query.data do
          "counter-yes" -> :lie
          "counter-no" -> :normal
        end

      Helpers.answer_counter(message.message_id, :nikita, answer_type)
    end

    %{reply | halt: true}
  end
end
