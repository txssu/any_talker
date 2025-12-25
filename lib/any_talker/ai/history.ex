defmodule AnyTalker.AI.History do
  @moduledoc false

  alias AnyTalker.AI.History.Key
  alias AnyTalker.Cache

  defstruct messages: []

  def new do
    %__MODULE__{}
  end

  def new(messages) do
    %__MODULE__{messages: Enum.reverse(messages)}
  end

  def append(%__MODULE__{} = history, messages) when is_list(messages) do
    Enum.reduce(messages, history, &append(&2, &1))
  end

  def append(%__MODULE__{} = history, message) do
    %{history | messages: [message | history.messages]}
  end

  def messages(%__MODULE__{messages: messages}) do
    messages
    |> Enum.reverse()
    |> Enum.uniq_by(fn msg ->
      case msg.uniq_key do
        nil -> make_ref()
        key -> key
      end
    end)
  end

  def set_last_uniq_key(%__MODULE__{messages: [last | rest]}, uniq_key) do
    %__MODULE__{messages: [%{last | uniq_key: uniq_key} | rest]}
  end

  @doc """
  Returns response_id and added_messages_ids
  """
  def get(%Key{} = key) do
    case Cache.get(key) do
      nil -> new()
      %__MODULE__{} = history -> history
    end
  end

  def put(%Key{} = key, %__MODULE__{} = history) do
    Cache.put(key, history)
  end
end
