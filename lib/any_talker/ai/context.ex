defmodule AnyTalker.AI.Context do
  @moduledoc false

  @required_keys ~w[chat_id user_id message_id]a

  @enforce_keys @required_keys

  defstruct @required_keys
end
