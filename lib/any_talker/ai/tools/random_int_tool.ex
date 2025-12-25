defmodule AnyTalker.AI.RandomIntTool do
  @moduledoc false
  @behaviour AnyTalker.AI.Tool

  alias AnyTalker.AI.Tool.Function
  alias AnyTalker.AI.Tool.FunctionArg

  def spec do
    %Function{
      name: "random_int",
      description: "Returns a random integer between min and max (inclusive)",
      args: [
        %FunctionArg{name: "min", type: "integer", description: "Minimum value (inclusive)"},
        %FunctionArg{name: "max", type: "integer", description: "Maximum value (inclusive)"}
      ]
    }
  end

  def call(%{"min" => min, "max" => max}, _context) when min <= max do
    {:ok, Enum.random(min..max)}
  end

  def call(%{"min" => _min, "max" => _max}, _context) do
    {:error, "min must be less than or equal to max"}
  end
end
