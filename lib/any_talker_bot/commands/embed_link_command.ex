defmodule AnyTalkerBot.EmbedLinkCommand do
  @moduledoc """
  Handles inline queries for converting links to embedded preview versions.

  This command takes URLs and replaces domains with their embedded preview equivalents.
  Supports both full URLs (https://x.com/...) and partial URLs (x.com/...).
  """

  alias AnyTalkerBot.Config.EmbedDomains
  alias AnyTalkerBot.Reply
  alias ExGram.Model.InlineQueryResultArticle
  alias ExGram.Model.InputTextMessageContent

  @doc """
  Handles inline query for link embedding.

  ## Example

      EmbedLinkCommand.handle_inline_query(reply, query)
  """
  def handle_inline_query(reply, query) do
    case parse_and_transform_url(query.query) do
      {:ok, original_url, transformed_url, domain_changed?} ->
        send_inline_result(reply, query, original_url, transformed_url, domain_changed?)

      {:error, :invalid_url} ->
        send_inline_help(reply, query)
    end
  end

  defp parse_and_transform_url(""), do: {:error, :invalid_url}

  defp parse_and_transform_url(text) do
    text = String.trim(text)

    with {:ok, url} <- normalize_url(text),
         {:ok, uri} <- parse_uri(url),
         {:ok, new_host} <- extract_and_replace_host(uri) do
      new_url = build_url(uri, new_host)
      domain_changed? = new_host != uri.host

      {:ok, url, new_url, domain_changed?}
    else
      _error -> {:error, :invalid_url}
    end
  end

  defp normalize_url(text) do
    url =
      if String.starts_with?(text, ["http://", "https://"]) do
        text
      else
        "https://#{text}"
      end

    {:ok, url}
  end

  defp parse_uri(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) and host != "" ->
        {:ok, URI.parse(url)}

      _otherwise ->
        {:error, :invalid_url}
    end
  end

  defp extract_and_replace_host(uri) do
    case uri.host do
      nil -> {:error, :no_host}
      host -> {:ok, EmbedDomains.replace_domain(host)}
    end
  end

  defp build_url(uri, new_host) do
    URI.to_string(%{uri | host: new_host})
  end

  defp send_inline_result(reply, query, original_url, transformed_url, domain_changed?) do
    {title, description} =
      if domain_changed? do
        {"Embedded link", "#{original_url} → #{transformed_url}"}
      else
        {"Link", original_url}
      end

    result = %InlineQueryResultArticle{
      type: "article",
      id: "embed_link",
      title: title,
      description: description,
      input_message_content: %InputTextMessageContent{
        message_text: transformed_url
      }
    }

    Reply.answer_inline_query(reply, query.id, [result])
  end

  defp send_inline_help(reply, query) do
    help_text = """
    Вставьте ссылку для создания embedded превью.
    """

    result = %InlineQueryResultArticle{
      type: "article",
      id: "embed_link_help",
      title: "Встроенные ссылки",
      description: "Конвертация ссылок в embedded версии",
      input_message_content: %InputTextMessageContent{
        message_text: String.trim(help_text)
      }
    }

    Reply.answer_inline_query(reply, query.id, [result])
  end
end
