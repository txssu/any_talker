defmodule AnyTalker.AI.ToolsRegistry do
  @moduledoc false

  modules = [
    AnyTalker.AI.NowTool,
    AnyTalker.AI.CreateTaskAtTool,
    AnyTalker.AI.CreateTaskAfterTool
  ]

  function_name_mapping =
    modules
    |> Enum.filter(&(&1.type() == :function))
    |> Map.new(&{&1.name(), &1})
    |> Macro.escape()

  def get_function_module_by_name(name) do
    Map.fetch(unquote(function_name_mapping), name)
  end

  specs =
    modules
    |> Enum.map(& &1.spec())
    |> Macro.escape()

  def list_specs, do: unquote(specs)
end
