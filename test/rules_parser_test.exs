defmodule LiveViewNative.Stylesheet.RulesParserTest do
  use ExUnit.Case
  doctest LiveViewNative.Stylesheet.RulesParser

  alias LiveViewNative.Stylesheet.RulesParser

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
      """

      result = RulesParser.parse(rules, :mock)

      assert result == [
        {:{}, [], [:foobar, [], [1, 2, 3]]},
        {:{}, [], [:foobar, [], [1, 2, {:number, [], Elixir}]]}
      ]
    end

    test "will raise when parser is not found" do
      assert_raise RuntimeError, "No parser found for `:other`", fn ->
        RulesParser.parse("", :other)
      end
    end
  end
end
