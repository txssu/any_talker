defmodule AnyTalkerBot.MarkdownUtils do
  @moduledoc false

  def to_html(text) do
    Telegex.Marked.as_html(text)
  end
end
