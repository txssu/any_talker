defmodule AnyTalker.CommandParser.Command do
  @moduledoc """
  A node in the command specification tree.

  ## Fields

  | Field       | Type          | Description                                     |
  |-------------|---------------|-------------------------------------------------|
  | name        | atom          | Command identifier                              |
  | labels      | list(string)  | Full names — all unambiguous prefixes accepted  |
  | args        | list(Arg.t()) | Argument specs (leaf commands only)             |
  | subcommands | list(t())     | Child command nodes                             |
  """

  alias AnyTalker.CommandParser.Arg

  @type t :: %__MODULE__{
          name: atom(),
          labels: [String.t()],
          args: [Arg.t()],
          subcommands: [t()]
        }

  defstruct [:name, labels: [], args: [], subcommands: []]
end
