defmodule AnyTalker.AI.SitesClient do
  @moduledoc false

  def get(url) do
    with {:ok, %{body: resp_body}} <- Tesla.get(client(), url) do
      to_md(resp_body)
    end
  end

  defp to_md(binary) do
    result = Html2Markdown.convert(binary, %{non_content_tags: non_content_tags(), navigation_classes: []})

    with md when is_binary(md) <- result do
      {:ok, md}
    end
  end

  def client do
    Tesla.client(
      [
        {Tesla.Middleware.Headers, [{"user-agent", user_agent()}]}
      ],
      Tesla.Adapter.Mint
    )
  end

  def user_agent do
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0.1 Safari/605.1.15"
  end

  def non_content_tags do
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
