defmodule AnyTalker.LocalizationUtils do
  @moduledoc false

  def pluralize(number, one, few, many) do
    n = rem(abs(number), 100)

    if n in 11..14 do
      many
    else
      case rem(n, 10) do
        1 -> one
        n when n in 2..4 -> few
        _other -> many
      end
    end
  end
end
