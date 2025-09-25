defmodule AnyTalker.AI.History do
  @moduledoc false
  alias AnyTalker.AI.History.Key
  alias AnyTalker.Cache

  defstruct response_id: nil, added_messages_ids: []

  def new do
    %__MODULE__{}
  end

  def new(response_id, added_messages_ids) do
    %__MODULE__{response_id: response_id, added_messages_ids: added_messages_ids}
  end

  def new(%__MODULE__{} = history, response_id, message_id) do
    %{history | response_id: response_id, added_messages_ids: [message_id | history.added_messages_ids]}
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
