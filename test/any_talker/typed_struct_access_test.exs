defmodule AnyTalker.TypedStructAccessTest do
  use ExUnit.Case, async: true

  alias AnyTalker.TypedStructAccess

  require TypedStructAccess

  defmodule Inner do
    @moduledoc false
    defstruct [:value]
  end

  defmodule Middle do
    @moduledoc false
    defstruct [:inner, :data]
  end

  defmodule Outer do
    @moduledoc false
    defstruct [:middle]
  end

  defp get_middle_inner_value(outer) do
    TypedStructAccess.get(outer.middle.inner.value, [Middle, Inner])
  end

  defp get_middle_inner(outer) do
    TypedStructAccess.get(outer.middle.inner, Middle)
  end

  defp get_middle_data_key(outer) do
    TypedStructAccess.get(outer.middle.data.key, [Middle, Map])
  end

  defp get_middle_data_nested_value(outer) do
    TypedStructAccess.get(outer.middle.data.nested.value, [Middle, Map, Inner])
  end

  describe "get/2 with structs" do
    test "accesses nested struct fields" do
      outer = %Outer{middle: %Middle{inner: %Inner{value: 42}}}

      assert get_middle_inner_value(outer) == 42
    end

    test "returns nil when intermediate struct is nil" do
      outer = %Outer{middle: nil}

      assert get_middle_inner_value(outer) == nil
    end

    test "returns nil when deeply nested struct is nil" do
      outer = %Outer{middle: %Middle{inner: nil}}

      assert get_middle_inner_value(outer) == nil
    end

    test "accesses single level with a single type" do
      outer = %Outer{middle: %Middle{inner: %Inner{value: "hello"}}}

      assert get_middle_inner(outer) == %Inner{value: "hello"}
    end
  end

  describe "get/2 with Map" do
    test "accesses a plain map field" do
      outer = %Outer{middle: %Middle{data: %{key: "value"}}}

      assert get_middle_data_key(outer) == "value"
    end

    test "returns nil when map is nil" do
      outer = %Outer{middle: %Middle{data: nil}}

      assert get_middle_data_key(outer) == nil
    end

    test "returns nil when struct before map is nil" do
      outer = %Outer{middle: nil}

      assert get_middle_data_key(outer) == nil
    end

    test "works with Map in the middle of the chain" do
      data = %Outer{middle: %Middle{data: %{nested: %Inner{value: 99}}}}

      assert get_middle_data_nested_value(data) == 99
    end

    test "works with Map in the middle when map is nil" do
      data = %Outer{middle: %Middle{data: %{nested: nil}}}

      assert get_middle_data_nested_value(data) == nil
    end
  end
end
