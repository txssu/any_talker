defmodule AnyTalker.AI.Sites.Default do
  @moduledoc """
  Default processor for websites. Converts HTML to markdown.

  Always matches as a fallback processor.
  """

  @behaviour AnyTalker.AI.Sites.Processor

  alias AnyTalker.AI.Sites.Processor

  @impl Processor
  def match?(_uri), do: true

  @impl Processor
  def process(%Tesla.Env{body: body}) do
    AnyTalker.Ai.Sites.Common.to_md(body)
  end
end
