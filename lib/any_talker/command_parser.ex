defmodule AnyTalker.CommandParser do
  @moduledoc """
  Platform-agnostic command parser with multilingual prefix matching,
  ambiguity detection, and fuzzy typo suggestions.

  Commands are specified as a tree of `%Command{}` nodes. Each command
  declares only its full label names; all valid prefix abbreviations are
  derived automatically at parse time.

  ## Examples

      iex> parse("add https://example.com", root_spec)
      {:ok, %ParseResult{command: :add, path: [:add], args: %{url: "https://example.com"}, raw_input: "add https://example.com"}}

      iex> parse("г н Tech", root_spec)
      {:ok, %ParseResult{command: :new, path: [:group, :new], args: %{name: "Tech"}, raw_input: "г н Tech"}}

  """

  alias AnyTalker.CommandParser.Arg
  alias AnyTalker.CommandParser.Command
  alias AnyTalker.CommandParser.ParseResult

  @type parse_error ::
          {:error, :ambiguous, [String.t()]}
          | {:error, :not_found, [String.t()]}
          | {:error, :missing_arg, atom()}
          | {:error, :empty}

  @doc """
  Parses an input string against the subcommands of `root`.

  Returns `{:ok, %ParseResult{}}` on success, or a tagged error tuple.

  ## Examples

      iex> parse("add https://example.com", root_spec)
      {:ok, %ParseResult{command: :add, path: [:add], args: %{url: "https://example.com"}, raw_input: "add https://example.com"}}

      iex> parse("addd https://example.com", root_spec)
      {:error, :not_found, ["add"]}

  """
  def parse(input, %Command{} = root) do
    trimmed = String.trim(input)
    tokens = String.split(trimmed, ~r/\s+/, trim: true)
    do_parse(tokens, root.subcommands, [], input)
  end

  defp do_parse([], _commands, _path, _raw_input), do: {:error, :empty}

  defp do_parse([token | rest], commands, path, raw_input) do
    downcased = String.downcase(token)

    matches =
      Enum.filter(commands, fn cmd ->
        Enum.any?(cmd.labels, &String.starts_with?(String.downcase(&1), downcased))
      end)

    case matches do
      [cmd] ->
        new_path = [cmd.name | path]

        if cmd.subcommands == [] do
          bind_args(rest, cmd.args, cmd.name, Enum.reverse(new_path), raw_input)
        else
          do_parse(rest, cmd.subcommands, new_path, raw_input)
        end

      [] ->
        {:error, :not_found, fuzzy_suggestions(token, commands)}

      many ->
        {:error, :ambiguous, Enum.flat_map(many, & &1.labels)}
    end
  end

  defp bind_args(tokens, arg_specs, command, path, raw_input) do
    arg_specs
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, %{}}, fn {%Arg{name: name, required: required}, idx}, {:ok, acc} ->
      case {Enum.at(tokens, idx), required} do
        {nil, true} -> {:halt, {:error, :missing_arg, name}}
        {nil, false} -> {:cont, {:ok, acc}}
        {value, _required} -> {:cont, {:ok, Map.put(acc, name, value)}}
      end
    end)
    |> case do
      {:ok, args} ->
        {:ok, %ParseResult{command: command, path: path, args: args, raw_input: raw_input}}

      error ->
        error
    end
  end

  defp fuzzy_suggestions(token, commands) do
    downcased = String.downcase(token)

    Enum.flat_map(commands, fn cmd ->
      Enum.filter(cmd.labels, &close_match?(downcased, &1))
    end)
  end

  defp close_match?(downcased_token, label) do
    label_down = String.downcase(label)
    dist = levenshtein(downcased_token, label_down)
    threshold = min(2, floor(String.length(label_down) * 0.4))
    dist <= threshold
  end

  defp levenshtein(s1, s2) do
    chars1 = String.graphemes(s1)
    chars2 = String.graphemes(s2)
    n = length(chars2)
    init_row = Map.new(0..n, fn j -> {j, j} end)

    chars1
    |> Enum.with_index(1)
    |> Enum.reduce(init_row, fn {c1, i}, prev ->
      chars2
      |> Enum.with_index(1)
      |> Enum.reduce(%{0 => i}, &levenshtein_cell(c1, prev, &1, &2))
    end)
    |> Map.fetch!(n)
  end

  defp levenshtein_cell(c1, prev, {c2, j}, row) do
    cost = if c1 == c2, do: 0, else: 1
    min_val = Enum.min([Map.fetch!(row, j - 1) + 1, Map.fetch!(prev, j) + 1, Map.fetch!(prev, j - 1) + cost])
    Map.put(row, j, min_val)
  end
end
