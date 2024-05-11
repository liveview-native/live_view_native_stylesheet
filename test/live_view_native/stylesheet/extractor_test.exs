defmodule LiveViewNative.Stylesheet.ExtractorTest do
  use ExUnit.Case

  def parse_style(template, path) do
    template
    |> LiveViewNative.Stylesheet.Extractor.parse_style(path)
    |> Enum.map(&(elem(&1, 0)))
  end

  describe "style attribute parser" do
    test "can parse out the style attribute from a tag" do
      template = """
      <Text style="a"></Text>
      """

      assert parse_style(template, "nofile") == ["a"]
    end

    test "can parse multiple definitions" do
      template = """
      <Text style="a"></Text>
      <Text style="b"></Text>
      """

      assert parse_style(template, "nofile") == ["a", "b"]
    end

    test "will ignore illegal matches" do
      template = """
      style="illegal"
      <Text style="a"></Text>
      """

      assert parse_style(template, "nofile") == ["a"]
    end

    test "will parse the attribute value" do
      template = """
      <Text style="a;b"></Text>
      """

      assert parse_style(template, "nofile") == ["a", "b"]
    end

    test "will collapse empty segments" do
      template = """
      <Text style="a;b ;; ;;"></Text>
      """

      assert parse_style(template, "nofile") == ["a", "b"]
    end

    test "parse ignore whitespace" do
      template = """
      <Text style = "a" ></Text>
      """

      assert parse_style(template, "nofile") == ["a"]
    end

    test "parse string from bracket" do
      template = """
      <Text style={"a"}></Text>
      """

      assert parse_style(template, "nofile") == ["a"]
    end

    test "parse list of strings from bracket" do
      template = """
      <Text style={[
        "a",
        "b"
      ]}></Text>
      """

      assert parse_style(template, "nofile") == ["a", "b"]
    end

    test "styles that have quotes are properly encoded" do
      template = """
      <Text style={[
        ~S'attr("test")'
      ]}></Text>
      """

      assert parse_style(template, "nofile") == [~S'attr("test")']
    end
  end
end
