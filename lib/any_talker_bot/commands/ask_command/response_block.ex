defmodule AnyTalkerBot.AskCommand.ResponseBlock do
  @moduledoc """
  Behaviour for response blocks that can be prepended to AI responses.

  Each block extracts relevant data from Generation results and formats it
  as an HTML blockquote to be added at the beginning of the response.
  """
  alias AnyTalker.Accounts.User
  alias AnyTalker.AI.Generation

  @doc """
  Extracts and formats blockquote content from generation results.

  Returns `nil` if no relevant data found, otherwise returns formatted HTML string.
  """
  @callback extract(%Generation{}, %User{}) :: String.t() | nil

  @blocks [
    AnyTalkerBot.AskCommand.YouTubeSummaryBlock,
    AnyTalkerBot.AskCommand.ReminderBlock
  ]

  def prepend_all(text, %Generation{} = gen, %User{} = user) do
    @blocks
    |> Enum.map(& &1.extract(gen, user))
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> text
      blocks -> Enum.join(blocks, "\n\n") <> "\n\n" <> text
    end
  end
end
