defmodule AnyTalker.AI.OpenRouter.Completions.DecoderTest do
  use ExUnit.Case, async: true

  alias AnyTalker.AI.OpenRouter.Completions.Decoder

  describe "decode/1" do
    test "returns error when response contains an error field" do
      data = %{
        "error" => %{
          "code" => 429,
          "message" => "Rate limit exceeded",
          "metadata" => %{}
        }
      }

      assert {:error, {:api_error, 429, "Rate limit exceeded"}} = Decoder.decode(data)
    end

    test "returns error when response contains an error field without code" do
      data = %{"error" => %{"message" => "Internal server error"}}

      assert {:error, {:api_error, nil, "Internal server error"}} = Decoder.decode(data)
    end

    test "decodes text response normally when no error" do
      data = %{
        "choices" => [
          %{
            "finish_reason" => "stop",
            "message" => %{"role" => "assistant", "content" => "Hello!"}
          }
        ]
      }

      assert {:ok, response} = Decoder.decode(data)
      assert response.data.content == "Hello!"
    end
  end
end
