defmodule AnyTalkerBot.TextProcessorTest do
  use ExUnit.Case, async: true

  alias AnyTalkerBot.TextProcessor

  describe "extract_http_code/1" do
    test "extracts code surrounded by spaces" do
      assert 404 == TextProcessor.extract_http_code("error 404 not found")
    end

    test "extracts code at the start of text" do
      assert 501 == TextProcessor.extract_http_code("501 internal server error")
    end

    test "extracts code at the end of text" do
      assert 201 == TextProcessor.extract_http_code("status code 201")
    end

    test "extracts code followed by punctuation" do
      assert 501 == TextProcessor.extract_http_code("got a 501!")
      assert 404 == TextProcessor.extract_http_code("error 404.")
      assert 503 == TextProcessor.extract_http_code("returned 503,")
    end

    test "extracts code preceded by punctuation" do
      assert 401 == TextProcessor.extract_http_code("error: 401")
      assert 403 == TextProcessor.extract_http_code("(403)")
    end

    test "extracts code surrounded by letters" do
      assert 404 == TextProcessor.extract_http_code("abc404def")
      assert 404 == TextProcessor.extract_http_code("error404code")
      assert 404 == TextProcessor.extract_http_code("ф404ф")
    end

    test "returns nil when code is surrounded by digits" do
      assert nil == TextProcessor.extract_http_code("1404")
      assert nil == TextProcessor.extract_http_code("4041")
      assert nil == TextProcessor.extract_http_code("14041")
    end

    test "returns nil when number is not an HTTP code" do
      assert nil == TextProcessor.extract_http_code("error 999")
      assert nil == TextProcessor.extract_http_code("code 123")
    end

    test "returns nil for text without numbers" do
      assert nil == TextProcessor.extract_http_code("no codes here")
    end

    test "returns first matching code when multiple present" do
      assert 404 == TextProcessor.extract_http_code("404 and 501")
    end

    test "extracts 1xx codes" do
      assert 101 == TextProcessor.extract_http_code("status 101")
    end

    test "extracts 2xx codes" do
      assert 201 == TextProcessor.extract_http_code("201 created")
      assert 204 == TextProcessor.extract_http_code("no content 204")
    end

    test "extracts 3xx codes" do
      assert 301 == TextProcessor.extract_http_code("redirect 301")
      assert 302 == TextProcessor.extract_http_code("302 found")
    end

    test "extracts 4xx codes" do
      assert 401 == TextProcessor.extract_http_code("401 unauthorized")
      assert 418 == TextProcessor.extract_http_code("I'm a teapot 418")
      assert 429 == TextProcessor.extract_http_code("429 too many requests")
    end

    test "extracts 5xx codes" do
      assert 502 == TextProcessor.extract_http_code("bad gateway 502")
      assert 503 == TextProcessor.extract_http_code("service unavailable 503")
    end

    test "handles empty string" do
      assert nil == TextProcessor.extract_http_code("")
    end

    test "handles non-binary input" do
      assert nil == TextProcessor.extract_http_code(nil)
      assert nil == TextProcessor.extract_http_code(123)
    end

    test "extracts code with newlines" do
      assert 404 == TextProcessor.extract_http_code("error\n404\nfound")
    end

    test "extracts code with tabs" do
      assert 501 == TextProcessor.extract_http_code("error\t501\there")
    end

    test "extracts code attached to letter on one side" do
      assert 404 == TextProcessor.extract_http_code("error404 happened")
      assert 404 == TextProcessor.extract_http_code("got 404error")
    end

    test "extracts code with underscore boundary" do
      assert 404 == TextProcessor.extract_http_code("error_404_found")
    end

    test "extracts code with hyphen boundary" do
      assert 501 == TextProcessor.extract_http_code("error-501-server")
    end
  end

  describe "extract_slash_command/2" do
    test "extracts command from entities" do
      text = "/start hello"
      message = %{entities: [%{type: "bot_command", offset: 0, length: 6}]}

      assert "/start" == TextProcessor.extract_slash_command(text, message)
    end

    test "extracts first command when multiple present" do
      text = "/first and /second"

      message = %{
        entities: [
          %{type: "bot_command", offset: 0, length: 6},
          %{type: "bot_command", offset: 11, length: 7}
        ]
      }

      assert "/first" == TextProcessor.extract_slash_command(text, message)
    end

    test "extracts command with offset in the middle of text" do
      text = "Тест /test_123 команда"
      message = %{entities: [%{type: "bot_command", offset: 5, length: 9}]}

      assert "/test_123" == TextProcessor.extract_slash_command(text, message)
    end

    test "returns nil when no bot_command entity" do
      text = "Нет команд здесь"
      message = %{entities: [%{type: "url", offset: 0, length: 5}]}

      assert nil == TextProcessor.extract_slash_command(text, message)
    end

    test "returns nil when entities is empty" do
      assert nil == TextProcessor.extract_slash_command("text", %{entities: []})
    end

    test "returns nil when entities is nil" do
      assert nil == TextProcessor.extract_slash_command("text", %{entities: nil})
    end

    test "returns nil when message has no entities key" do
      assert nil == TextProcessor.extract_slash_command("text", %{})
    end

    test "handles non-binary text" do
      assert nil == TextProcessor.extract_slash_command(nil, %{entities: []})
    end
  end
end
