defmodule AnyTalker.AI.Response do
  @moduledoc false
  use TypedStruct

  typedstruct do
    field :id, String.t() | nil
    field :output_text, String.t() | nil
    field :total_tokens, integer() | nil
    field :model, String.t() | nil
  end
end
