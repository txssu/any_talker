defmodule AnyTalkerBot.Command do
  @moduledoc false
  alias AnyTalkerBot.Reply

  @callback call(Reply.t()) :: Reply.t()
end
