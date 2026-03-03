defmodule AnyTalkerBot.CleanUrlCommand do
  @moduledoc false
  use AnyTalkerBot, :command

  alias AnyTalker.ClearUrl
  alias AnyTalkerBot.HtmlUtils
  alias AnyTalkerBot.Reply
  alias ExGram.Model.Message

  @url_regex ~r/https?:\/\/[^\s<>"')\]]+/

  @impl AnyTalkerBot.Command
  def call(%Reply{} = reply) do
    %Message{} = message = Reply.message(reply)

    text = extract_text(message)

    case extract_and_clean_urls(text) do
      [] ->
        Reply.send_message(reply, "Не нашёл ссылок в сообщении.", as_reply?: true)

      cleaned_urls ->
        response =
          cleaned_urls
          |> Enum.with_index(1)
          |> Enum.map_join("\n", fn {url, idx} -> "#{idx}. #{HtmlUtils.escape_html(url)}" end)

        Reply.send_message(reply, response, mode: :html, as_reply?: true)
    end
  end

  defp extract_text(%Message{text: text, reply_to_message: nil}) when is_binary(text), do: text
  defp extract_text(%Message{reply_to_message: %Message{text: text}}) when is_binary(text), do: text
  defp extract_text(%Message{reply_to_message: %Message{caption: caption}}) when is_binary(caption), do: caption
  defp extract_text(_message), do: ""

  defp extract_and_clean_urls(text) do
    @url_regex
    |> Regex.scan(text)
    |> List.flatten()
    |> Enum.map(&ClearUrl.clean/1)
    |> Enum.uniq()
  end
end
