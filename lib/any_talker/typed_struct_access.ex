# credo:disable-for-this-file Credo.Check.Consistency.UnusedVariableNames
defmodule AnyTalker.TypedStructAccess do
  @moduledoc false
  defmacro get(path, types) do
    {keys, root} = extract_path(path)
    type_list = extract_types(types)

    build_nested_case(root, keys, type_list)
  end

  defp extract_path(ast) do
    extract_path(ast, [])
  end

  defp extract_path({{:., _, [inner, key]}, _, []}, acc) do
    extract_path(inner, [key | acc])
  end

  defp extract_path(root, acc) do
    {acc, root}
  end

  defp extract_types({:__aliases__, _, _} = single_type) do
    [single_type]
  end

  defp extract_types(types) when is_list(types) do
    types
  end

  defp build_nested_case(expr, [key], []) do
    quote do
      unquote(expr).unquote(key)
    end
  end

  defp build_nested_case(expr, [key | rest_keys], [type | rest_types]) do
    var = Macro.unique_var(:v, __MODULE__)
    inner = build_nested_case(var, rest_keys, rest_types)

    quote do
      case unquote(expr).unquote(key) do
        nil -> nil
        %unquote(type){} = unquote(var) -> unquote(inner)
      end
    end
  end
end
