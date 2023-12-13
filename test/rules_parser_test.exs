defmodule LiveViewNative.Stylesheet.RulesParserTest do
  use ExUnit.Case
  doctest LiveViewNative.Stylesheet.RulesParser

  alias LiveViewNative.Stylesheet.RulesParser

  @file_path __ENV__.file
  @file_name Path.basename(__ENV__.file)
  @module __ENV__.module

  describe "Rules.fetch_parser" do
    test "when a parser is available with the given format the designated parser module is returned" do
      {:ok, parser} = RulesParser.fetch(:mock)

      assert parser == MockRulesParser
    end

    test "when no parser is available an error is returned" do
      {:error, message} = RulesParser.fetch(:other)

      assert message == "No parser found for `:other`"
    end
  end

  describe "Rules.parse" do
    test "extracts the rules and parses to desired format" do
      rules = """
      rule-1
      rule-2
      """

      result = RulesParser.parse(rules, :mock)

      assert result == [1, 2]
    end

    test "will rewrite parsed rules for macro escape but will hoist Elixir terms" do
      rules = """
      rule-21
      rule-22
      rule-ime
      """

      result = RulesParser.parse(rules, :mock)

      assert result == [
               {:{}, [], [:foobar, [], [1, 2, 3]]},
               {:{}, [], [:foobar, [], [1, 2, {:number, [], Elixir}]]},
               {:{}, [], [:color, [], [color: [{:{}, [], [:., [], [nil, :red]]}]]]}
             ]
    end

    test "will raise when parser is not found" do
      assert_raise RuntimeError, "No parser found for `:other`", fn ->
        RulesParser.parse("", :other)
      end
    end

    test "will pass annotation data through to the rules parser" do
      rules = """
      rule-21-annotated
      rule-21
      """

      result = RulesParser.parse(rules, :mock, file: @file_path, line: 1, module: @module)

      assert result == [
               {:{}, [], [:foobar, [file: @file_name, line: 1, module: @module], [1, 2, 3]]},
               {:{}, [], [:foobar, [], [1, 2, 3]]},
             ]
    end
  end

  describe "Rules.Helper.parse" do
    def annotation(line), do: [file: @file_name, line: line, module: @module]

    def parse_helper_function(source, opts \\ []) when is_list(opts) do
      file = Keyword.get(opts, :file, "")
      module = Keyword.get(opts, :module, "")
      line = Keyword.get(opts, :line, 1)

      parse_opts = [
        byte_offset: 0,
        line: {line, 0},
        context: %{
          file: file,
          module: module
        }
      ]

      MockRulesHelpers.helper_function(source, parse_opts)
    end

    test "can parse standard helpers" do
      input = "to_float(number)"

      output =
        {Elixir, annotation(1), {:to_float, annotation(1), [{:number, annotation(1), Elixir}]}}

      assert {:ok, [result], _, _, _, _} =
               parse_helper_function(input, file: @file_path, module: @module)

      assert result == output
    end

    test "can parse additional helpers" do
      input = "to_abc(family)"

      output =
        {Elixir, annotation(1), {:to_abc, annotation(1), [{:family, annotation(1), Elixir}]}}

      assert {:ok, [result], _, _, _, _} =
               parse_helper_function(input, file: @file_path, module: @module)

      assert result == output
    end

    test "can parse additional helpers (2)" do
      input = "to_abc(
          family
        )"

      output =
        {Elixir, annotation(1), {:to_abc, annotation(1), [{:family, annotation(2), Elixir}]}}

      assert {:ok, [result], _, _, _, _} =
               parse_helper_function(input, file: @file_path, module: @module)

      assert result == output
    end

    test "can't parse unknown helper functions" do
      input = "to_unknown(family)"

      assert {:error, "expected a 1-arity helper function" <> _, _, _, _, _} =
               parse_helper_function(input, file: @file_path, module: @module)
    end
  end
end
