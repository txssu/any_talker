defmodule AnyTalker.CommandParserTest do
  use ExUnit.Case, async: true

  alias AnyTalker.CommandParser
  alias AnyTalker.CommandParser.Arg
  alias AnyTalker.CommandParser.Command
  alias AnyTalker.CommandParser.ParseResult

  # Shared test spec used across all test cases
  defp spec do
    %Command{
      name: :root,
      labels: [],
      args: [],
      subcommands: [
        %Command{
          name: :news,
          labels: ["news", "новости"],
          args: [%Arg{name: :group, required: false}],
          subcommands: []
        },
        %Command{
          name: :add,
          labels: ["add", "добавить"],
          args: [%Arg{name: :url, required: true}, %Arg{name: :group, required: false}],
          subcommands: []
        },
        %Command{
          name: :remove,
          labels: ["remove", "удалить"],
          args: [%Arg{name: :url, required: true}],
          subcommands: []
        },
        %Command{
          name: :group,
          labels: ["group", "группа"],
          args: [],
          subcommands: [
            %Command{
              name: :new,
              labels: ["new", "новая"],
              args: [%Arg{name: :name, required: true}],
              subcommands: []
            },
            %Command{
              name: :delete,
              labels: ["delete", "удалить"],
              args: [%Arg{name: :name, required: true}],
              subcommands: []
            }
          ]
        }
      ]
    }
  end

  describe "structs" do
    test "Command struct defaults" do
      cmd = %Command{name: :test, labels: ["test"]}
      assert cmd.args == []
      assert cmd.subcommands == []
    end

    test "Arg struct defaults" do
      arg = %Arg{name: :url}
      assert arg.required == true
    end

    test "ParseResult struct" do
      result = %ParseResult{command: :add, path: [:add], args: %{url: "https://x.com"}, raw_input: "add https://x.com"}
      assert result.command == :add
    end
  end

  describe "parse/2 — prefix matching" do
    test "exact English match" do
      assert {:ok, result} = CommandParser.parse("add https://example.com", spec())
      assert result.command == :add
      assert result.path == [:add]
      assert result.args == %{url: "https://example.com"}
      assert result.raw_input == "add https://example.com"
    end

    test "single-character prefix match" do
      assert {:ok, result} = CommandParser.parse("a https://example.com", spec())
      assert result.command == :add
    end

    test "Russian full label" do
      assert {:ok, result} = CommandParser.parse("добавить https://example.com", spec())
      assert result.command == :add
    end

    test "Russian single-character prefix" do
      assert {:ok, result} = CommandParser.parse("д https://example.com", spec())
      assert result.command == :add
    end

    test "Russian multi-char prefix" do
      assert {:ok, result} = CommandParser.parse("доб https://example.com", spec())
      assert result.command == :add
    end

    test "case insensitive matching" do
      assert {:ok, result} = CommandParser.parse("ADD https://example.com", spec())
      assert result.command == :add
    end

    test "subcommand path — short prefixes" do
      assert {:ok, result} = CommandParser.parse("г н Tech", spec())
      assert result.command == :new
      assert result.path == [:group, :new]
      assert result.args == %{name: "Tech"}
    end

    test "subcommand path — full Russian labels" do
      assert {:ok, result} = CommandParser.parse("группа новая Технологии", spec())
      assert result.command == :new
      assert result.path == [:group, :new]
      assert result.args == %{name: "Технологии"}
    end

    test "optional arg present" do
      assert {:ok, result} = CommandParser.parse("news Tech", spec())
      assert result.command == :news
      assert result.args == %{group: "Tech"}
    end

    test "optional arg absent" do
      assert {:ok, result} = CommandParser.parse("news", spec())
      assert result.command == :news
      assert result.args == %{}
    end

    test "empty input returns :empty error" do
      assert {:error, :empty} = CommandParser.parse("", spec())
      assert {:error, :empty} = CommandParser.parse("   ", spec())
    end

    test "subcommand required but not provided returns :empty" do
      assert {:error, :empty} = CommandParser.parse("г", spec())
    end
  end

  describe "parse/2 — arg validation" do
    test "missing required arg returns error" do
      assert {:error, :missing_arg, :url} = CommandParser.parse("add", spec())
    end

    test "missing required subcommand arg returns error" do
      assert {:error, :missing_arg, :name} = CommandParser.parse("group new", spec())
    end
  end

  describe "parse/2 — ambiguity" do
    test "ambiguous prefix returns :ambiguous with all matching labels" do
      ambiguous_spec = %Command{
        name: :root,
        labels: [],
        args: [],
        subcommands: [
          %Command{name: :alpha, labels: ["alpha", "альфа"], args: [], subcommands: []},
          %Command{name: :another, labels: ["another", "альтернатива"], args: [], subcommands: []}
        ]
      }

      assert {:error, :ambiguous, suggestions} = CommandParser.parse("аль", ambiguous_spec)
      assert "альфа" in suggestions
      assert "альтернатива" in suggestions
    end

    test "unambiguous prefix is not flagged as ambiguous" do
      assert {:ok, result} = CommandParser.parse("н", spec())
      assert result.command == :news
    end
  end

  describe "parse/2 — fuzzy suggestions" do
    test "typo in command suggests closest match" do
      assert {:error, :not_found, suggestions} = CommandParser.parse("addd https://example.com", spec())
      assert "add" in suggestions
    end

    test "completely unknown command with no close match returns empty suggestions" do
      assert {:error, :not_found, []} = CommandParser.parse("xyzqwerty https://example.com", spec())
    end

    test "typo in Russian command suggests closest match" do
      assert {:error, :not_found, suggestions} = CommandParser.parse("нвости", spec())
      assert "новости" in suggestions
    end
  end
end
