defmodule AnyTalker.AvatarGenerator do
  @moduledoc """
  Generates SVG avatars with initials and deterministic background colors.
  """

  @colors [
    "#FF6B6B",
    "#4ECDC4",
    "#45B7D1",
    "#FFA07A",
    "#98D8C8",
    "#F7DC6F",
    "#BB8FCE",
    "#85C1E2",
    "#F8B739",
    "#52B788"
  ]

  @doc """
  Generates an SVG avatar for a user with initials and a deterministic background color.

  ## Examples

      iex> AnyTalker.AvatarGenerator.generate("John", "Doe", 1)
      "<?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?>..."

      iex> AnyTalker.AvatarGenerator.generate("Alice", nil, 2)
      "<?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?>..."
  """
  def generate(first_name, last_name, user_id) do
    initials = get_initials(first_name, last_name)
    color = get_color(user_id)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <circle cx="50" cy="50" r="50" fill="#{color}"/>
      <text x="50" y="50" font-family="sans-serif" font-size="36" font-weight="500" fill="white" text-anchor="middle" dominant-baseline="central">#{initials}</text>
    </svg>
    """
  end

  defp get_initials(first_name, nil) do
    first_name
    |> String.trim()
    |> String.first()
    |> String.upcase()
  end

  defp get_initials(first_name, last_name) when is_binary(last_name) do
    first_initial =
      first_name
      |> String.trim()
      |> String.first()
      |> String.upcase()

    last_initial =
      last_name
      |> String.trim()
      |> String.first()
      |> String.upcase()

    "#{first_initial}#{last_initial}"
  end

  defp get_color(user_id) do
    index = rem(user_id, length(@colors))
    Enum.at(@colors, index)
  end
end
