defmodule AnyTalker.AI.Tool.FunctionArg do
  @moduledoc false
  alias __MODULE__

  @keys [:name]
  @encoder_keys [:type, :format, :description, :items, :max_items, :min_items, :minimum]

  defstruct @keys ++ @encoder_keys

  def encoder_keys, do: @encoder_keys

  defimpl AnyTalker.AI.OpenRouter.Completions.Encoder do
    def encode(%FunctionArg{} = arg) do
      AnyTalker.MapExt.reject_nil_values(%{
        "type" => arg.type,
        "format" => arg.format,
        "description" => arg.description,
        "items" => arg.items,
        "maxItems" => arg.max_items,
        "minItems" => arg.min_items,
        "minimum" => arg.minimum
      })
    end
  end
end
