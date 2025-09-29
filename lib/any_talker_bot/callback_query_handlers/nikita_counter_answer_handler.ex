defmodule AnyTalkerBot.NikitaCounterAnswerHandler do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.Counters.Helpers
  alias AnyTalkerBot.Reply2

  @impl AnyTalkerBot.Command
  def call(%Reply2{message: {:callback_query, callback_query}} = reply) do
    if Helpers.nikita_id?(callback_query.from.id) do
      message = callback_query.message

      answer_type =
        case callback_query.data do
          "counter-yes" -> :lie
          "counter-no" -> :normal
        end

      Helpers.answer_counter(message.message_id, :nikita, answer_type)
    end

    Reply2.halt(reply)
  end
end
