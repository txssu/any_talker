defmodule AnyTalker.AI.RandomChoiceTool do
  @moduledoc false
  use AnyTalker.AI.Tool, type: :function

  alias AnyTalker.AI.Function
  alias AnyTalker.AI.Tool

  @impl Tool
  def spec do
    %{
      type: "function",
      name: name(),
      description: "Selects a random item from a list of choices (up to 10 items)",
      strict: true,
      parameters: %{
        additionalProperties: false,
        type: "object",
        properties: %{
          choices: %{
            type: "array",
            items: %{type: "string"},
            description: "List of choices to select from (maximum 10 items)",
            maxItems: 10,
            minItems: 1
          }
        },
        required: ["choices"]
      }
    }
  end

  @impl Function
  def name, do: "random_choice"

  @impl Function
  def exec(%{"choices" => choices}, _context) when is_list(choices) do
    cond do
      Enum.empty?(choices) ->
        {:error, "Choices list cannot be empty"}

      length(choices) > 10 ->
        {:error, "Maximum 10 choices allowed"}

      true ->
        Enum.random(choices)
    end
  end

  def exec(_params, _context) do
    {:error, "Invalid parameters: choices must be a list"}
  end
end
