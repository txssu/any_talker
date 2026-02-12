defmodule AnyTalker.AI.OpenRouter.Completions.Decoder do
  @moduledoc """
  Decodes OpenRouter Completions API responses to structs.

  ## Example

      iex> data = %{"choices" => [%{"message" => %{"role" => "assistant", "content" => "Hi!"}}]}
      iex> AnyTalker.AI.OpenRouter.Completions.Decoder.decode(data)
      %AnyTalker.AI.Response{...}
  """
  use Pathex

  alias AnyTalker.AI.Response

  @doc """
  Decodes a map from OpenRouter Completions API to Response struct.
  """
  @spec decode(map()) :: Response.t()
  def decode(data) when is_map(data) do
    finish_reason_path = path "choices" / 0 / "finish_reason", :json
    finish_reason = Pathex.get(data, finish_reason_path)
    {:ok, %Response{data: decode_data(finish_reason, data), usage: decode_usage(data)}}
  end

  def decode(_data) do
    {:error, :client_error}
  end

  defp decode_data("tool_calls", data) do
    message = get_in(data, ["choices", Access.at(0), "message"])
    tool_call = get_in(message, ["tool_calls", Access.at(0)])

    %Response.ToolCall{
      reasoning_details: message["reasoning_details"],
      function_name: get_in(tool_call, ["function", "name"]),
      arguments: decode_arguments(get_in(tool_call, ["function", "arguments"])),
      tool_call_id: tool_call["id"]
    }
  end

  defp decode_data(_finish_reason, data) do
    content_path = path "choices" / 0 / "message" / "content", :json
    %Response.TextOutput{content: Pathex.get(data, content_path)}
  end

  defp decode_arguments(nil), do: %{}
  defp decode_arguments(""), do: %{}
  defp decode_arguments(json) when is_binary(json), do: Jason.decode!(json)
  defp decode_arguments(map) when is_map(map), do: map

  defp decode_usage(%{"usage" => %{"total_tokens" => total} = usage}) when is_integer(total) do
    %Response.Usage{total_tokens: total, cost: decode_cost(usage)}
  end

  defp decode_usage(_data), do: nil

  defp decode_cost(%{"cost" => cost}) when is_float(cost) and cost > 0, do: Decimal.from_float(cost)
  defp decode_cost(%{"cost" => cost}) when is_integer(cost) and cost > 0, do: Decimal.new(cost)

  defp decode_cost(%{"cost_details" => %{"upstream_inference_cost" => cost}}) when is_float(cost) and cost > 0,
    do: Decimal.from_float(cost)

  defp decode_cost(%{"cost_details" => %{"upstream_inference_cost" => cost}}) when is_integer(cost) and cost > 0,
    do: Decimal.new(cost)

  defp decode_cost(_usage), do: Decimal.new(0)
end
