defmodule AnyTalker.AI.History do
  @moduledoc false
  alias AnyTalker.AI.History.Key
  alias AnyTalker.Cache

  defstruct messages: []

  def new do
    %__MODULE__{}
  end

  def new(messages) do
    %__MODULE__{messages: messages}
  end

  def append(%__MODULE__{} = history, message) do
    %{history | messages: [message | history.messages]}
  end

  @doc """
  Returns response_id and added_messages_ids
  """
  def get(%Key{} = key) do
    case Cache.get(key) do
      nil -> %__MODULE__{}
      %__MODULE__{} = history -> history
    end
  end

  def put(%Key{} = key, %__MODULE__{} = history) do
    Cache.put(key, history)
  end
end
