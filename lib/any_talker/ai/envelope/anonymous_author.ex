defmodule AnyTalker.AI.Envelope.AnonymousAuthor do
  @moduledoc """
  Represents an anonymous author when the original sender is hidden.

  Used for forwarded messages from `MessageOriginHiddenUser` where
  we only have the display name, not the actual user.
  """

  defstruct [:display_name]

  @type t :: %__MODULE__{display_name: String.t()}
end
