defmodule AnyTalker.AI.NowFunction do
  @moduledoc false
  @behaviour AnyTalker.AI.Function

  alias AnyTalker.AI.Function

  @impl Function
  def name, do: "now"

  @impl Function
  def spec do
    %{
      type: "function",
      name: name(),
      description: "Returns current date and time",
      strict: true,
      parameters: %{additionalProperties: false, type: "object", properties: %{}}
    }
  end

  @impl Function
  def exec(_params, _extra) do
    DateTime.utc_now()
  end
end
