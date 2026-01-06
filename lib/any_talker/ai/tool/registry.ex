defmodule AnyTalker.AI.Tool.Registry do
  @moduledoc false
  alias AnyTalker.AI.Tool.Function

  @tools [
    AnyTalker.AI.CreateTaskAfterTool,
    AnyTalker.AI.CreateTaskAtTool,
    AnyTalker.AI.FetchPageTool,
    AnyTalker.AI.NowTool,
    AnyTalker.AI.RandomChoiceTool,
    AnyTalker.AI.RandomIntTool,
    AnyTalker.AI.SearchTool,
    AnyTalker.AI.YouTubeTool
  ]

  def list do
    Enum.map(@tools, & &1.spec())
  end

  def get_module_by_func_name(func_name) do
    @tools
    |> Map.new(&{&1, &1.spec()})
    |> Enum.find_value(fn {module, %Function{name: name}} -> name == func_name && module end)
  end
end
