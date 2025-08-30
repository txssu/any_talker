defmodule AnyTalker.Ai.FunctionsRegistry do
  @moduledoc false

  modules = [
    AnyTalker.AI.NowFunction
  ]

  functions_mapping =
    modules
    |> Map.new(&{&1.name(), &1})
    |> Macro.escape()

  def functions, do: unquote(functions_mapping)

  def module_by_name(name) do
    Map.fetch(functions(), name)
  end
end
