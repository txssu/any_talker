defmodule AnyTalkerBot.Command do
  @moduledoc false

  @type reply :: term()

  @callback call(reply) :: reply
end
