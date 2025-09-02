defmodule AnyTalker.AI.NowTool do
  @moduledoc false
  use AnyTalker.AI.Tool, type: :function

  alias AnyTalker.AI.Function
  alias AnyTalker.AI.Tool

  @impl Tool
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
  def name, do: "now"

  @impl Function
  def exec(_params, _extra) do
    DateTime.utc_now(:second)
  end
end
