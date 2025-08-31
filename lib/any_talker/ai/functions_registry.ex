defmodule AnyTalker.Ai.FunctionsRegistry do
  @moduledoc false

  modules = [
    AnyTalker.AI.NowFunction,
    AnyTalker.AI.CreateTaskFunction
  ]

  name_mapping =
    modules
    |> Map.new(&{&1.name(), &1})
    |> Macro.escape()

  def get_module_by_name(name) do
    Map.fetch(unquote(name_mapping), name)
  end

  specs =
    modules
    |> Enum.map(& &1.spec())
    |> Macro.escape()

  def list_specs, do: unquote(specs)
end
