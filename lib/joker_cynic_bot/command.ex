defmodule JokerCynicBot.Command do
  @moduledoc false
  alias JokerCynicBot.Reply

  @callback call(Reply.t()) :: Reply.t()
end
