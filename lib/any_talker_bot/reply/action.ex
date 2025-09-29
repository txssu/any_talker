defmodule AnyTalkerBot.Reply.Action do
  @moduledoc """
  Behaviour for executing different types of reply actions.

  This behaviour defines the contract for any action module that can be executed
  as part of a Reply. Implementations should handle the actual execution
  of the action (e.g., sending a message, editing a message, sending an inline callback).

  ## Example

      defmodule Reply.Message do
        @behaviour Reply.Action

        def execute(%Reply{action: %__MODULE__{}} = reply) do
          # Send message logic
        end
      end
  """

  @doc """
  Executes the action from the given reply.

  The implementation should extract its action struct from `reply.action`
  and perform the necessary operations.

  Returns `{:ok, result}` on success or `{:error, reason}` on failure.
  """
  @callback execute(reply :: struct()) :: {:ok, any()} | {:error, any()}
end
