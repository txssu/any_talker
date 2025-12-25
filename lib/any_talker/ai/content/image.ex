defmodule AnyTalker.AI.Content.Image do
  @moduledoc false
  alias __MODULE__

  defstruct [:image_base64]

  def new(img) do
    %__MODULE__{image_base64: img}
  end

  defimpl AnyTalker.AI.OpenRouter.Completions.Encoder do
    def encode(%Image{image_base64: img}) do
      %{
        "type" => "image_url",
        "image_url" => %{
          "url" => img
        }
      }
    end
  end
end
