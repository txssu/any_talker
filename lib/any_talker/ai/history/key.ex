defmodule AnyTalker.AI.History.Key do
  @moduledoc false

  defstruct ~w[chat_id message_id]a

  def new(chat_id, message_id) do
    %__MODULE__{chat_id: chat_id, message_id: message_id}
  end
end
