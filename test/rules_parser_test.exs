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

      assert result == ["rule-1", "rule-2"]
    end

    test "will raise when parser is not found" do
      assert_raise RuntimeError, "No parser found for `:other`", fn ->
        RulesParser.parse("", :other)
      end
    end

    test "will pass annotation data through to the rules parser" do
      rules = """
      rule-annotated
      """

      result = RulesParser.parse(rules, :mock, file: @file_path, line: 1, module: @module)

      assert result == [
               {:foobar, [file: @file_name, line: 1, module: @module], [1, 2, 3]}
             ]
    end
  end
end
