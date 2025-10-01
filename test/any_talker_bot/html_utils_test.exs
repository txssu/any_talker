defmodule AnyTalkerBot.HtmlUtilsTest do
  use ExUnit.Case, async: true

  alias AnyTalkerBot.HtmlUtils

  describe "escape_html_preserving_tags/1" do
    test "escapes < in plain text" do
      assert "x &lt; y" == HtmlUtils.escape_html_preserving_tags("x < y")
    end

    test "escapes > in plain text" do
      assert "x &gt; y" == HtmlUtils.escape_html_preserving_tags("x > y")
    end

    test "escapes & in plain text" do
      assert "A &amp; B" == HtmlUtils.escape_html_preserving_tags("A & B")
    end

    test "escapes multiple special characters" do
      assert "x &lt; y &amp; z &gt; w" ==
               HtmlUtils.escape_html_preserving_tags("x < y & z > w")
    end

    test "preserves simple bold tag" do
      assert "Use <b>bold</b> text" ==
               HtmlUtils.escape_html_preserving_tags("Use <b>bold</b> text")
    end

    test "preserves simple italic tag" do
      assert "Use <i>italic</i> text" ==
               HtmlUtils.escape_html_preserving_tags("Use <i>italic</i> text")
    end

    test "preserves strong tag" do
      assert "Use <strong>strong</strong> text" ==
               HtmlUtils.escape_html_preserving_tags("Use <strong>strong</strong> text")
    end

    test "preserves em tag" do
      assert "Use <em>emphasis</em> text" ==
               HtmlUtils.escape_html_preserving_tags("Use <em>emphasis</em> text")
    end

    test "preserves underline tag" do
      assert "Use <u>underline</u> text" ==
               HtmlUtils.escape_html_preserving_tags("Use <u>underline</u> text")
    end

    test "preserves ins tag" do
      assert "Use <ins>inserted</ins> text" ==
               HtmlUtils.escape_html_preserving_tags("Use <ins>inserted</ins> text")
    end

    test "preserves strikethrough tags" do
      assert "Use <s>strikethrough</s> text" ==
               HtmlUtils.escape_html_preserving_tags("Use <s>strikethrough</s> text")

      assert "Use <strike>strikethrough</strike> text" ==
               HtmlUtils.escape_html_preserving_tags("Use <strike>strikethrough</strike> text")

      assert "Use <del>deleted</del> text" ==
               HtmlUtils.escape_html_preserving_tags("Use <del>deleted</del> text")
    end

    test "preserves code tag" do
      assert "Use <code>code</code> here" ==
               HtmlUtils.escape_html_preserving_tags("Use <code>code</code> here")
    end

    test "preserves pre tag" do
      assert "Use <pre>preformatted</pre> text" ==
               HtmlUtils.escape_html_preserving_tags("Use <pre>preformatted</pre> text")
    end

    test "preserves tg-spoiler tag" do
      assert "Use <tg-spoiler>spoiler</tg-spoiler> text" ==
               HtmlUtils.escape_html_preserving_tags("Use <tg-spoiler>spoiler</tg-spoiler> text")
    end

    test "preserves blockquote tag" do
      assert "Use <blockquote>quote</blockquote> text" ==
               HtmlUtils.escape_html_preserving_tags("Use <blockquote>quote</blockquote> text")
    end

    test "preserves a tag with href attribute" do
      assert ~S|Click <a href="https://example.com">here</a> now| ==
               HtmlUtils.escape_html_preserving_tags(~S|Click <a href="https://example.com">here</a> now|)
    end

    test "preserves a tag with href using single quotes" do
      assert ~S|Click <a href='https://example.com'>here</a> now| ==
               HtmlUtils.escape_html_preserving_tags(~S|Click <a href='https://example.com'>here</a> now|)
    end

    test "preserves code tag with class attribute" do
      assert ~S|<code class="language-python">print("hello")</code>| ==
               HtmlUtils.escape_html_preserving_tags(~S|<code class="language-python">print("hello")</code>|)
    end

    test "preserves pre with code tag with class" do
      assert ~S|<pre><code class="language-python">code</code></pre>| ==
               HtmlUtils.escape_html_preserving_tags(~S|<pre><code class="language-python">code</code></pre>|)
    end

    test "preserves blockquote with expandable attribute" do
      assert ~S|<blockquote expandable="">quote</blockquote>| ==
               HtmlUtils.escape_html_preserving_tags(~S|<blockquote expandable="">quote</blockquote>|)
    end

    test "preserves span with tg-spoiler class" do
      assert ~S|<span class="tg-spoiler">spoiler</span>| ==
               HtmlUtils.escape_html_preserving_tags(~S|<span class="tg-spoiler">spoiler</span>|)
    end

    test "preserves nested tags" do
      assert "<b><i>bold italic</i></b>" ==
               HtmlUtils.escape_html_preserving_tags("<b><i>bold italic</i></b>")
    end

    test "escapes special chars outside tags" do
      assert "Use <b>bold</b> for x &lt; y" ==
               HtmlUtils.escape_html_preserving_tags("Use <b>bold</b> for x < y")
    end

    test "escapes special chars before and after tags" do
      assert "x &lt; <b>bold</b> &gt; y" ==
               HtmlUtils.escape_html_preserving_tags("x < <b>bold</b> > y")
    end

    test "preserves tags and escapes special chars in mixed content" do
      assert ~S|Check <a href="url">this</a> if x &lt; y &amp; z &gt; w| ==
               HtmlUtils.escape_html_preserving_tags(~S|Check <a href="url">this</a> if x < y & z > w|)
    end

    test "escapes invalid tags" do
      assert "&lt;invalid&gt;text&lt;/invalid&gt;" ==
               HtmlUtils.escape_html_preserving_tags("<invalid>text</invalid>")
    end

    test "escapes incomplete tags" do
      assert "test &lt;b incomplete" == HtmlUtils.escape_html_preserving_tags("test <b incomplete")
    end

    test "preserves valid tags even if mismatched" do
      # Note: We don't validate tag matching - that's Telegram's job
      # Our goal is to escape non-tag characters
      assert "test <b>text</i>" ==
               HtmlUtils.escape_html_preserving_tags("test <b>text</i>")
    end

    test "preserves already escaped entities" do
      assert "Already escaped: &lt; &gt; &amp;" ==
               HtmlUtils.escape_html_preserving_tags("Already escaped: &lt; &gt; &amp;")
    end

    test "preserves numeric entities" do
      assert "Numeric: &#123; &#xAB;" ==
               HtmlUtils.escape_html_preserving_tags("Numeric: &#123; &#xAB;")
    end

    test "escapes & that is not part of entity" do
      assert "A &amp; B but &lt; is entity" ==
               HtmlUtils.escape_html_preserving_tags("A & B but &lt; is entity")
    end

    test "handles empty string" do
      assert "" == HtmlUtils.escape_html_preserving_tags("")
    end

    test "handles string with only tags" do
      assert "<b></b>" == HtmlUtils.escape_html_preserving_tags("<b></b>")
    end

    test "handles string with only special chars" do
      assert "&lt;&gt;&amp;" == HtmlUtils.escape_html_preserving_tags("<>&")
    end

    test "handles complex real-world example" do
      input = """
      Для сравнения:
      - x < 5 означает "меньше"
      - A & B означает "и"

      Используй <b>жирный</b> или <a href="https://example.com">ссылку</a> для акцента.

      <pre><code class="language-python">
      if x < y:
          print("x меньше y")
      </code></pre>
      """

      expected = """
      Для сравнения:
      - x &lt; 5 означает "меньше"
      - A &amp; B означает "и"

      Используй <b>жирный</b> или <a href="https://example.com">ссылку</a> для акцента.

      <pre><code class="language-python">
      if x &lt; y:
          print("x меньше y")
      </code></pre>
      """

      assert expected == HtmlUtils.escape_html_preserving_tags(input)
    end
  end
end
