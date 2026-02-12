defmodule AnyTalker.AI.Response do
  @moduledoc false
  alias __MODULE__

  defmodule Usage do
    @moduledoc false
    defstruct [:total_tokens, :cost]
  end

  defstruct [:data, :usage]

  @type t :: %__MODULE__{}

  def total_tokens(%__MODULE__{usage: %Usage{total_tokens: total}}), do: total
  def total_tokens(%__MODULE__{}), do: 0

  def cost(%__MODULE__{usage: %Usage{cost: %Decimal{} = cost}}), do: cost
  def cost(%__MODULE__{}), do: Decimal.new(0)

  def set_accumulated_usage(%__MODULE__{} = response, total_tokens, %Decimal{} = total_cost) do
    %{response | usage: %Usage{total_tokens: total_tokens, cost: total_cost}}
  end

  defimpl AnyTalker.AI.ToMessage do
    def to_message(%Response{} = resp) do
      AnyTalker.AI.ToMessage.to_message(resp.data)
    end
  end
end
