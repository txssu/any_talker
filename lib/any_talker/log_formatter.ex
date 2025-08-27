defmodule AnyTalker.LogFormatter do
  @moduledoc false
  def format(level, message, _timestamp, metadata) do
    # "$metadata[$level] $message\n"
    level_msg = ["[", to_string(level), "]"]

    result = ["\n", level_msg, " ", message]

    add_metadata(result, metadata, level_msg)
  end

  defp add_metadata(result, [], _level_msg) do
    [result, "\n"]
  end

  defp add_metadata(result, [{key, value} | rest], level_msg) do
    result = [result, "\n[metadata] ", to_string(key), "=", inspect(value)]

    add_metadata(result, rest, level_msg)
  end
end
