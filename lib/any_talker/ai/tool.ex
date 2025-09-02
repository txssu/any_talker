defmodule AnyTalker.AI.Tool do
  @moduledoc false

  @callback spec() :: map()

  @callback type() :: atom()

  defmacro __using__(type: type) do
    quote do
      @behaviour unquote(__MODULE__)

      unquote(extensions_by_type(type))
    end
  end

  def extensions_by_type(:basic) do
    quote do
      def type, do: :tool
    end
  end

  def extensions_by_type(:function) do
    quote do
      @behaviour AnyTalker.AI.Function
      def type, do: :function
    end
  end
end
