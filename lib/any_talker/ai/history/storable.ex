defprotocol AnyTalker.AI.History.Storable do
  @moduledoc """
  Protocol for objects that can be stored in history.
  """

  alias AnyTalker.AI.History.Key

  @doc """
  Returns a key for looking up this object in history
  """
  @spec to_key(t) :: Key.t()
  def to_key(object)
end

defimpl AnyTalker.AI.History.Storable, for: ExGram.Model.Message do
  alias AnyTalker.TypedStructAccess
  alias ExGram.Model.Chat
  alias ExGram.Model.Message

  require TypedStructAccess

  def to_key(%Message{} = message) do
    chat_id = TypedStructAccess.get(message.chat.id, [Chat])
    AnyTalker.AI.History.Key.new(chat_id, message.message_id)
  end
end
