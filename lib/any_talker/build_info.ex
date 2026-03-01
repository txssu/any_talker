defmodule AnyTalker.BuildInfo do
  @moduledoc false

  @external_resource ".git/HEAD"

  hash =
    case File.read(".git/HEAD") do
      {:ok, "ref: " <> ref_path} ->
        ref_file = ".git/#{String.trim(ref_path)}"
        @external_resource ref_file

        case File.read(ref_file) do
          {:ok, content} -> String.slice(content, 0, 7)
          :error -> "undefined"
        end

      {:ok, hash} ->
        hash
        |> String.trim()
        |> String.slice(0, 7)

      :error ->
        "undefined"
    end

  @git_short_hash hash

  def git_short_hash, do: @git_short_hash
end
