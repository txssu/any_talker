defmodule AnyTalker.BuildInfo do
  @moduledoc false

  @external_resource git_revision_file = ".git/HEAD"

  git_hash_file =
    if File.exists?(git_revision_file) do
      head_contents = File.read!(git_revision_file)

      if String.starts_with?(head_contents, "ref:") do
        ref_path =
          head_contents
          |> String.replace("ref:", "")
          |> String.trim()

        ".git/#{ref_path}"
      end
    end

  @external_resource git_hash_file

  hash =
    git_hash_file
    |> File.read!()
    |> String.slice(0, 7)

  @git_short_hash hash

  @spec git_short_hash() :: String.t()
  def git_short_hash, do: @git_short_hash
end
