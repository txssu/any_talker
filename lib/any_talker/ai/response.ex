defmodule AnyTalker.AI.Response do
  @moduledoc false
  import Pathex
  import Pathex.Lenses

  alias AnyTalker.Parser

  defstruct id: nil,
            output_text: nil,
            total_tokens: nil,
            model: nil,
            function_calls: []

  def parse(params) do
    parsers = %{
      id: Parser.not_nil_parser(& &1["id"], "response.id not found"),
      total_tokens: Parser.not_nil_parser(& &1["usage"]["total_tokens"], "response.usage.total_tokens not found"),
      model: Parser.not_nil_parser(& &1["model"], "response.model not found"),
      output_text: &cast_output_text/1,
      function_calls: &cast_function_calls/1
    }

    Parser.parse(%__MODULE__{}, params, parsers)
  end

  defp cast_output_text(api_response) do
    output_text_path =
      path("content")
      ~> star()
      ~> matching(%{"type" => "output_text"})
      ~> path("text")

    text =
      api_response
      |> from_output("message", output_text_path)
      |> Enum.join()

    {:ok, text}
  end

  defp cast_function_calls(api_response) do
    function_calls =
      api_response
      |> from_output("function_call")
      |> Enum.map(fn fc ->
        case AnyTalker.AI.FunctionCall.parse(fc) do
          {:ok, parsed} -> parsed
          {:error, _parse_error} -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, function_calls}
  end

  defp from_output(data, type, next_path \\ nil) do
    base_path =
      path("output")
      ~> star()
      ~> matching(%{"type" => ^type})

    result_path =
      if next_path do
        base_path ~> next_path
      else
        base_path
      end

    data
    |> Pathex.get(result_path)
    |> List.wrap()
    |> List.flatten()
  end
end
