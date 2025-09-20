defmodule AnyTalker.Cldr do
  @moduledoc false
  use Cldr,
    locales: [:ru],
    providers: [Cldr.Number]
end
