defmodule AnyTalker.Timezone do
  @moduledoc false

  @doc """
  Formats UTC offset in seconds to human-readable format like "GMT+3" or "GMT-8".

  ## Examples

      iex> AnyTalker.Timezone.format_utc_offset(10800)
      "GMT+3"

      iex> AnyTalker.Timezone.format_utc_offset(-28800)
      "GMT-8"

  """
  def format_utc_offset(seconds) do
    hours = div(seconds, 3600)
    num = if hours >= 0, do: "+#{hours}", else: "#{hours}"
    "GMT#{num}"
  end
end
