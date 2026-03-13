defmodule AnyTalker.CommandParser.Arg do
  @moduledoc """
  Argument specification for a command.

  ## Fields

  | Field    | Type    | Description                              |
  |----------|---------|------------------------------------------|
  | name     | atom    | Argument name, used as key in ParseResult |
  | required | boolean | Whether this argument is required         |
  """

  @type t :: %__MODULE__{
          name: atom(),
          required: boolean()
        }

  defstruct [:name, required: true]
end
