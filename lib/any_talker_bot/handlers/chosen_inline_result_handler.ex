defmodule AnyTalkerBot.Handlers.ChosenInlineResultHandler do
  @moduledoc false

  alias AnyTalkerBot.Reply
  alias ExGram.Model.ChosenInlineResult

  def execute(reply, {:update, %{chosen_inline_result: %ChosenInlineResult{result_id: "ask"} = result}}) do
    AnyTalkerBot.InlineHandlers.AskInlineHandler.handle_chosen_inline_result(reply, result)
  end

  def execute(reply, _message), do: Reply.halt(reply)
end
