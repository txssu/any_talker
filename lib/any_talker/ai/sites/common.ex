defmodule AnyTalker.Ai.Sites.Common do
  @moduledoc false

  def to_md(binary) do
    result =
      Html2Markdown.convert(binary, %{
        non_content_tags: non_content_tags(),
        navigation_classes: []
      })

    case result do
      {:error, error} -> {:error, error}
      md_binary -> {:ok, md_binary}
    end
  end

  defp non_content_tags do
    [
      "aside",
      "audio",
      "base",
      "button",
      "datalist",
      "embed",
      "form",
      "iframe",
      "input",
      "keygen",
      "nav",
      "noscript",
      "object",
      "output",
      "script",
      "select",
      "source",
      "style",
      "svg",
      "template",
      "textarea",
      "track",
      "img"
    ]
  end
end
