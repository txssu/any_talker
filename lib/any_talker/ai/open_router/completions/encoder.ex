defprotocol AnyTalker.AI.OpenRouter.Completions.Encoder do
  @moduledoc """
  Protocol for encoding structs to OpenRouter Completions API format.

  ## Example

      iex> message = %AnyTalker.AI.Message{role: :user, content: "Hello"}
      iex> AnyTalker.AI.OpenRouter.Completions.Encoder.encode(message)
      %{"role" => "user", "content" => "Hello"}
  """

  @doc """
  Encodes a struct to a map suitable for OpenRouter Completions API.
  """
  @spec encode(t) :: map() | list()
  def encode(struct)
end
