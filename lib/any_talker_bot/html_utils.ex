defmodule AnyTalkerBot.HtmlUtils do
  @moduledoc """
  Utilities for processing HTML content for Telegram messages.

  Telegram supports a limited set of HTML tags in parse_mode="HTML".
  This module helps escape special HTML characters while preserving valid tags.
  """

  # Valid Telegram HTML tags (simple tags without attributes)
  @simple_tags ~w(b strong i em u ins s strike del code pre tg-spoiler blockquote)

  # Pattern for simple opening tags
  @simple_open_tag_pattern Enum.join(@simple_tags, "|")

  # Pattern for simple closing tags
  @simple_close_tag_pattern Enum.join(@simple_tags, "|")

  @doc """
  Escapes HTML special characters while preserving valid Telegram HTML tags.

  This function:
  - Escapes `<`, `>`, and `&` in regular text to `&lt;`, `&gt;`, and `&amp;`
  - Preserves valid Telegram HTML tags like `<b>`, `<i>`, `<a href="">`, etc.
  - Handles nested tags correctly

  ## Supported tags

  - Simple: `<b>`, `<strong>`, `<i>`, `<em>`, `<u>`, `<ins>`, `<s>`, `<strike>`, `<del>`, `<code>`, `<pre>`, `<tg-spoiler>`, `<blockquote>`
  - With attributes: `<a href="...">`, `<code class="language-...">`, `<blockquote expandable="...">`, `<span class="tg-spoiler">`

  ## Examples

      iex> escape_html_preserving_tags("Hello < world")
      "Hello &lt; world"

      iex> escape_html_preserving_tags("Use <b>bold</b> text")
      "Use <b>bold</b> text"

      iex> escape_html_preserving_tags("x < y and A & B")
      "x &lt; y and A &amp; B"

      iex> escape_html_preserving_tags("Click <a href=\\"url\\">here</a> for x > y")
      "Click <a href=\\"url\\">here</a> for x &gt; y"

  """
  def escape_html_preserving_tags(text) when is_binary(text) do
    do_escape(text, "")
  end

  # Main recursive function that processes the text character by character
  defp do_escape("", acc), do: acc

  # Handle ampersand - must be escaped unless it's part of an existing entity
  defp do_escape("&" <> rest, acc) do
    # Check if this is already an HTML entity (e.g., &lt;, &gt;, &amp;, &#...)
    case parse_existing_entity("&" <> rest) do
      {entity, remaining} ->
        do_escape(remaining, acc <> entity)

      nil ->
        do_escape(rest, acc <> "&amp;")
    end
  end

  # Handle opening angle bracket - check if it's a valid tag
  defp do_escape("<" <> rest, acc) do
    case parse_tag("<" <> rest) do
      {tag, remaining} ->
        # Found a valid tag, keep it as-is
        do_escape(remaining, acc <> tag)

      nil ->
        # Not a valid tag, escape it
        do_escape(rest, acc <> "&lt;")
    end
  end

  # Handle closing angle bracket in regular text
  defp do_escape(">" <> rest, acc) do
    do_escape(rest, acc <> "&gt;")
  end

  # Handle regular characters
  defp do_escape(<<char::utf8, rest::binary>>, acc) do
    do_escape(rest, acc <> <<char::utf8>>)
  end

  # Try to parse an existing HTML entity (to avoid double-escaping)
  defp parse_existing_entity(text) do
    # Match named entities (&lt;, &gt;, &amp;, &quot;, &apos;) or numeric entities (&#123; or &#xAB;)
    entity_regex = ~r/^(&(?:[a-zA-Z]+|#[0-9]+|#x[0-9A-Fa-f]+);)/

    case Regex.run(entity_regex, text) do
      [entity, entity] ->
        remaining = String.slice(text, String.length(entity)..-1//1)
        {entity, remaining}

      _no_match ->
        nil
    end
  end

  # Try to parse a valid HTML tag from the text
  defp parse_tag(text) do
    parse_simple_open_tag(text) ||
      parse_simple_close_tag(text) ||
      parse_a_tag(text) ||
      parse_code_tag_with_class(text) ||
      parse_blockquote_with_attr(text) ||
      parse_span_spoiler(text)
  end

  # Parse simple opening tag like <b>, <i>, etc.
  defp parse_simple_open_tag(text) do
    regex = ~r/^<(#{@simple_open_tag_pattern})>/

    case Regex.run(regex, text) do
      [tag, _tag_name] ->
        remaining = String.slice(text, String.length(tag)..-1//1)
        {tag, remaining}

      _no_match ->
        nil
    end
  end

  # Parse simple closing tag like </b>, </i>, etc.
  defp parse_simple_close_tag(text) do
    regex = ~r/^<\/(#{@simple_close_tag_pattern})>/

    case Regex.run(regex, text) do
      [tag, _tag_name] ->
        remaining = String.slice(text, String.length(tag)..-1//1)
        {tag, remaining}

      _no_match ->
        nil
    end
  end

  # Parse <a href="..."> tag
  defp parse_a_tag(text) do
    # Match <a href="..."> or <a href='...'>
    regex = ~r/^<a\s+href=["']([^"']*)["']>/

    case Regex.run(regex, text) do
      [tag, _href] ->
        remaining = String.slice(text, String.length(tag)..-1//1)
        {tag, remaining}

      _no_match ->
        # Try to match closing tag
        case Regex.run(~r/^<\/a>/, text) do
          [tag] ->
            remaining = String.slice(text, String.length(tag)..-1//1)
            {tag, remaining}

          _no_match ->
            nil
        end
    end
  end

  # Parse <code class="language-..."> tag (used inside <pre>)
  defp parse_code_tag_with_class(text) do
    regex = ~r/^<code(?:\s+class=["']([^"']*)["'])?>/

    case Regex.run(regex, text) do
      [tag | _rest] ->
        remaining = String.slice(text, String.length(tag)..-1//1)
        {tag, remaining}

      _no_match ->
        # Try closing tag
        case Regex.run(~r/^<\/code>/, text) do
          [tag] ->
            remaining = String.slice(text, String.length(tag)..-1//1)
            {tag, remaining}

          _no_match ->
            nil
        end
    end
  end

  # Parse <blockquote> or <blockquote expandable="...">
  defp parse_blockquote_with_attr(text) do
    # Match <blockquote expandable=""> or just <blockquote>
    regex = ~r/^<blockquote(?:\s+expandable=["'][^"']*["'])?>/

    case Regex.run(regex, text) do
      [tag | _rest] ->
        remaining = String.slice(text, String.length(tag)..-1//1)
        {tag, remaining}

      _no_match ->
        # Try closing tag
        case Regex.run(~r/^<\/blockquote>/, text) do
          [tag] ->
            remaining = String.slice(text, String.length(tag)..-1//1)
            {tag, remaining}

          _no_match ->
            nil
        end
    end
  end

  # Parse <span class="tg-spoiler"> tag
  defp parse_span_spoiler(text) do
    regex = ~r/^<span\s+class=["']tg-spoiler["']>/

    case Regex.run(regex, text) do
      [tag] ->
        remaining = String.slice(text, String.length(tag)..-1//1)
        {tag, remaining}

      _no_match ->
        # Try closing tag (but only if it was a spoiler span)
        # For simplicity, we'll accept any </span> when in this context
        # A more robust solution would track nesting
        case Regex.run(~r/^<\/span>/, text) do
          [tag] ->
            remaining = String.slice(text, String.length(tag)..-1//1)
            {tag, remaining}

          _no_match ->
            nil
        end
    end
  end
end
