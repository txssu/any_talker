defmodule AnyTalker.AI.RandomIntTool do
  @moduledoc false
  use AnyTalker.AI.Tool, type: :function

  alias AnyTalker.AI.Function
  alias AnyTalker.AI.Tool

  @impl Tool
  def spec do
    %{
      type: "function",
      name: name(),
      description: "Returns a random integer between min and max (inclusive)",
      strict: true,
      parameters: %{
        additionalProperties: false,
        type: "object",
        properties: %{
          min: %{type: "integer", description: "Minimum value (inclusive)"},
          max: %{type: "integer", description: "Maximum value (inclusive)"}
        },
        required: ["min", "max"]
      }
    }
  end

  @impl Function
  def name, do: "random_int"

  @impl Function
  def exec(%{"min" => min, "max" => max}, _context) when is_integer(min) and is_integer(max) do
    if min <= max do
      Enum.random(min..max)
    else
      {:error, "min must be less than or equal to max"}
    end
  end

  def exec(_params, _context) do
    {:error, "Invalid parameters: min and max must be integers"}
  end
end
