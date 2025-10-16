defmodule AnyTalker.AI.Sites.Processor do
  @moduledoc """
  Behaviour for site processors.

  Each processor must implement:
  - `match?/1` - Check if the processor can handle the given URL
  - `process/1` - Process the Tesla response
  """

  @doc """
  Checks if this processor can handle the given URI.

  ## Examples

      iex> uri = URI.parse("https://example.com")
      iex> Processor.match?(uri)
      true

  """
  @callback match?(uri :: URI.t()) :: boolean()

  @doc """
  Processes the Tesla response.

  ## Examples

      iex> Processor.process(%Tesla.Env{body: "..."})
      {:ok, processed_content}

  """
  @callback process(response :: Tesla.Env.t()) :: {:ok, String.t()} | {:error, term()}
end
