defmodule AnyTalker.AI.RandomChoiceTool do
  @moduledoc false
  @behaviour AnyTalker.AI.Tool

  alias AnyTalker.AI.Tool.Function
  alias AnyTalker.AI.Tool.FunctionArg

  def spec do
    %Function{
      name: "random_choice",
      description: "Selects a random item from a list of choices (up to 10 items)",
      args: [
        %FunctionArg{
          name: "choices",
          type: "array",
          items: %{"type" => "string"},
          description: "List of choices to select from (maximum 10 items)",
          max_items: 10,
          min_items: 1
        }
      ]
    }
  end

  def call(%{"choices" => choices}, _context) when is_list(choices) and length(choices) in 1..10 do
    {:ok, Enum.random(choices)}
  end

  def call(%{"choices" => choices}, _context) when is_list(choices) and choices == [] do
    {:error, "Choices list cannot be empty"}
  end

  def call(%{"choices" => choices}, _context) when is_list(choices) do
    {:error, "Maximum 10 choices allowed"}
  end

  def call(_params, _context) do
    {:error, "Invalid parameters: choices must be a list"}
  end
end
