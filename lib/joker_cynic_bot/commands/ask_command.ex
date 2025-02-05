defmodule JokerCynicBot.AskCommand do
  @moduledoc false
  alias JokerCynic.AI
  alias JokerCynicBot.Reply

  def call(%Reply{message: {:command, :ask, message}} = reply) do
    case message.text do
      "" ->
        %Reply{reply | text: "Используй: /ask текст-вопроса"}

      text ->
        reply_text = AI.ask(text)

        %Reply{reply | text: reply_text}
    end
  end
end
