defmodule AnyTalker.CommandParser.ParseResult do
  @moduledoc """
  Successful parse result returned by `AnyTalker.CommandParser.parse/2`.

  ## Fields

  | Field     | Type        | Description                         |
  |-----------|-------------|-------------------------------------|
  | command   | atom        | Matched command name                |
  | path      | list(atom)  | Full path from root to matched node |
  | args      | map         | Bound argument values by name       |
  | raw_input | string      | Original input string               |
  """

  @type t :: %__MODULE__{
          command: atom(),
          path: [atom()],
          args: map(),
          raw_input: String.t() | nil
        }

  defstruct [:command, :raw_input, path: [], args: %{}]
end
