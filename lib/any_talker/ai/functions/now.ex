defmodule AnyTalker.AI.NowFunction do
  @moduledoc false

  def name, do: "now"

  def spec do
    %{
      type: "function",
      name: name(),
      description: "Returns current date and time",
      strict: true,
      parameters: %{additionalProperties: false, type: "object", properties: %{}}
    }
  end

  def exec(_params) do
    DateTime.utc_now()
  end
end
