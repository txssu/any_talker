defmodule AnyTalker.Currency do
  @moduledoc """
  Currency conversion utilities for handling monetary amounts.

  All monetary amounts are stored internally as smallest currency units to avoid
  floating point precision issues.
  """

  @doc """
  Converts rubles to kopecks.
  """
  def rub(amount) do
    amount * 100
  end
end
