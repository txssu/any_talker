defmodule AnyTalker.AI.NowTool do
  @moduledoc false
  @behaviour AnyTalker.AI.Tool

  alias AnyTalker.AI.Tool.Function

  def spec do
    %Function{
      name: "now",
      description: "Returns current date and time",
      args: []
    }
  end

  def call(_params, _context) do
    now = DateTime.now!("Asia/Yekaterinburg")
    {:ok, now}
  end
end
