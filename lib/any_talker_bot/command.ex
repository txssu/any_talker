defmodule AnyTalkerBot.Command do
  @moduledoc false

  @type reply :: term()

  @callback call(reply) :: reply
  @callback call(reply, atom()) :: reply

  @optional_callbacks call: 1, call: 2
end
