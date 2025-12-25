defprotocol AnyTalker.AI.ToMessage do
  @moduledoc """
  Protocol for converting response data to Message struct.

  ## Example

      iex> text = %AnyTalker.AI.Response.TextOutput{content: "Hello"}
      iex> AnyTalker.AI.ToMessage.to_message(text)
      %AnyTalker.AI.Message{role: "assistant", content: "Hello"}
  """

  @doc """
  Converts a response data struct to a Message.
  """
  @spec to_message(t) :: AnyTalker.AI.Message.t()
  def to_message(data)
end
