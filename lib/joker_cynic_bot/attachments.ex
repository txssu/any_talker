defmodule JokerCynicBot.Attachments do
  @moduledoc false
  alias ExGram.Model.PhotoSize

  @max_area 1536 * 1024
  @spec best_fit_photo([PhotoSize.t()]) :: PhotoSize.t() | nil
  def best_fit_photo(sizes) when is_list(sizes) do
    sizes
    |> Enum.map(&{&1, photo_area(&1)})
    |> Enum.filter(fn {_photo, area} -> area < @max_area end)
    |> Enum.max_by(fn {_photo, area} -> area end, fn -> nil end)
    |> case do
      {photo, _area} -> photo
      nil -> nil
    end
  end

  @spec get_file_link(String.t()) :: String.t()
  def get_file_link(file_id) when is_binary(file_id) do
    options = [bot: JokerCynicBot.bot()]

    file_id
    |> ExGram.get_file!(options)
    |> ExGram.File.file_url(options)
  end

  defp photo_area(%PhotoSize{width: w, height: h}), do: w * h
end
