defmodule AnyTalker.AI.Tool.Function do
  @moduledoc false
  alias __MODULE__
  alias AnyTalker.AI.Tool.FunctionArg

  defstruct [:name, :description, :args]

  @type t :: %Function{}

  def arg_keys(%Function{} = func) do
    Enum.map(func.args, fn %FunctionArg{} = arg -> arg.name end)
  end

  defimpl AnyTalker.AI.OpenRouter.Completions.Encoder do
    def encode(%Function{} = func) do
      %{
        "type" => "function",
        "function" => %{
          "name" => func.name,
          "description" => func.description,
          "parameters" => %{
            "type" => "object",
            "required" => Function.arg_keys(func),
            "properties" =>
              Map.new(func.args, fn %FunctionArg{} = arg ->
                arg_data = AnyTalker.AI.OpenRouter.Completions.Encoder.encode(arg)
                {arg.name, arg_data}
              end)
          }
        }
      }
    end
  end
end
