defmodule AnyTalker.AI.NowTool do
  @moduledoc false
  @behaviour AnyTalker.AI.Tool

  alias AnyTalker.Accounts
  alias AnyTalker.AI.FunctionContext
  alias AnyTalker.AI.Tool.Function

  def spec do
    %Function{
      name: "now",
      description: "Returns current date and time",
      args: []
    }
  end

  def call(_params, %FunctionContext{user: user, chat: chat}) do
    timezone = Accounts.get_timezone(user, chat)

    now =
      timezone
      |> DateTime.now!()
      |> DateTime.truncate(:second)

    {:ok, now}
  end
end
