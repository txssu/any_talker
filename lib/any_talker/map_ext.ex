defmodule AnyTalker.MapExt do
  @moduledoc false
  def put_not_nil(map, key, value)
  def put_not_nil(map, _key, nil), do: map
  def put_not_nil(map, key, value), do: Map.put(map, key, value)

  def reject_nil_values(map) do
    Map.filter(map, fn {_k, v} -> v != nil end)
  end
end
